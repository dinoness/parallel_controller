# AGENTS.md

## 项目概述

本项目为**并联机器人运动控制器软件**，运行在 **ZMC（ZMotion Controller，深圳正运动技术）运动控制器**硬件平台上。控制系统通过 **EtherCAT 总线**连接 5 个伺服驱动器，实现 **5 轴并联机器人**（非串联）的运动控制；运动学解算采用闭环矢量法。上位机为 Qt 程序，通过 **MODBUS REG** 寄存器与控制器交换命令和状态。

仓库根目录同时存放了三个阶段的代码：

| 位置 | 说明 | 版本控制 |
|------|------|----------|
| 根目录 `*.bas` / `frame1000.c` / `t1.zpj` / `t1.so` | v1 原型代码：总线初始化、回零、单轴运动等功能的早期验证程序 | 已纳入 git |
| `v2/` | v2 版本：基于**有限状态机（FSM）+ 事件驱动**的模块化重构，**当前主力开发版本** | 已纳入 git |
| `v3/` | v3 版本：参考 **GRBL v1.1h** 架构的全面重写（protocol/planner/motion_control 分层），并附带 `grbl-learning-master/` 作为参考源码 | **未纳入 git**（被 `.gitignore` 忽略） |

各版本有各自的文档：`v2/AGENTS.md`（v2 架构细节）、`v3/README.md`（v3 完整设计文档，非常详尽）、`v2/register_assignment.md`（TABLE/MODBUS 资源分配）。修改对应版本代码时应同步更新对应文档。

## 技术栈

| 组件 | 语言/格式 | 说明 |
|------|----------|------|
| 主控程序 | RTBasic (`.bas`) | ZMC 控制器的 BASIC 方言，不区分大小写，在 ZDevelop IDE 中编写，**无需编译**，直接下载到控制器解释执行 |
| 运动学库 | C (`.c`/`.h`) | 自定义正逆解算法（CFRAME 1000），需交叉编译为 `.so` 由控制器运行时加载 |
| 向量数学库 | C (`myeigen.c/.h`) | 自实现 3D 向量/矩阵运算（vec3、mat3x3），替代 Eigen |
| SDK 头文件 | `zmcbuildin.h` | ZMC 官方 SDK，提供 `TYPE_FRAME`、`TYPE_TABLE` 等类型及数学函数声明 |
| 工程文件 | `.zpj` | ZDevelop IDE 工程文件（INI 格式，部分为 GBK 编码），`[FileList]` 节定义下载文件列表、下载顺序（`Down` 字段）和自动运行文件（`AutoRun=0`） |

参考手册：根目录 `RTBasic编程手册V1.1.2.pdf`（RTBasic 语言与指令的官方手册）。

## 构建与部署

### .bas 文件

通过 **ZDevelop IDE** 打开对应的 `.zpj` 工程，直接下载到控制器运行（Ctrl+D），无编译步骤。`.zpj` 中 `Down` 字段决定下载/加载顺序，`AutoRun=0` 的文件为上电自动运行的入口（各版本均为 `main.bas` 或 `motion1.bas`）。

### .c 文件（运动学库）

C 运动学库需编译为 `.so` 共享库，由控制器加载为自定义 CFRAME（frame ID = 1000）：

1. 使用 ZMC 提供的交叉编译工具链编译（`.zpj` 中配置 `ARM64 options=-std=c99` / `Win64 options=-std=c99`）
2. 将 `.so` 放到控制器可访问路径（根目录 `t1.so` 为已有编译产物）
3. BASIC 代码中通过 `DEFINE_CFRAME 1000,...` 定义机械手，`CONNFRAME` 连接运动学

C 库实现三个入口函数：`SOFRAME_INIT1000`（从 TABLE 读取几何参数）、`SOFRAME_RETRANS1000`（逆解：世界坐标 → 关节脉冲）、`SOFRAME_TRANS1000`（正解）。几何参数包括静平台铰链坐标 B[5]、动平台铰链坐标 M[5]、初始支链长度 limb0[5]、各关节脉冲系数。

## 代码组织

### 根目录（v1 原型）

- `motion1.bas` — 入口（AutoRun），总线初始化 + 电机参数配置
- `EtherCAT1.bas`、`home1.bas`、`para_config.bas`、`trace1.bas`、`motion3.bas`/`motion4.bas` — 各功能验证程序
- `Basic1.bas` — 语法试验；`33.md` — RTBasic 语法/指令学习笔记（非常有用，含寄存器、多任务、EtherCAT、运动指令等要点）
- `frame1000.c` + `myeigen.c/.h` — CFRAME 1000 运动学库源码；`t1.so` — 编译产物；`t1.zpj` — 工程文件

### v2/（FSM 版本，当前主力）

```
main.bas            # 主入口：初始化、主循环、事件分发
global_config.bas   # 全局常量（寄存器分配、状态/事件枚举、运动参数）
fsm.bas             # 有限状态机：事件获取、分发、Handle_SYS_* 状态处理、任务桩函数
ethercat_mgr.bas    # EtherCAT 总线初始化（扫描、轴映射、启动）
home_mgr.bas        # 回零管理（5 轴分两组，DATUM 模式 21+29/17）
manual_move_mgr.bas # 单轴手动控制
traj_move_mgr.bas   # 轨迹运动（开发中）
safety_mgr.bas      # 安全监控（心跳检测，独立任务）
robo_config.bas     # 机器人几何参数配置
frame1000.c / myeigen.c/.h / zmcbuildin.h  # C 运动学库
register_assignment.md  # TABLE 与 MODBUS_REG 资源分配文档
v2.zpj / AGENTS.md
```

架构要点：9 种系统状态（`SYS_BOOT`→`SYS_BUS_INIT`→`SYS_SERVO_READY`→`SYS_HOMING`→`SYS_READY`→`SYS_RUNNING`/`SYS_PAUSED`，异常态 `SYS_ERROR`/`SYS_ESTOP`）；上位机写 MODBUS 事件寄存器，主循环按优先级扫描分发；长耗时任务通过 `RUNTASK` 启动为后台任务，任务间互斥。详见 `v2/AGENTS.md`。

### v3/（GRBL 架构重写）

按 GRBL v1.1h 分层：`main.bas`（入口+主循环）、`system_def.bas`（状态机核心/常量/寄存器映射）、`protocol.bas`（命令协议+安全监控）、`motion_control.bas`（回零/点动/单轴/轨迹/闭环）、`planner.bas`（轨迹双缓冲池，10 块 × 100 条指令）、`sensor_mgr.bas`（传感器滤波 + PID 闭环）、`report.bas`（状态上报）、`ecat_mgr.bas`、`para_config.bas`、`robot_kinematics.c`（CFRAME 运动学）。命令协议基于命令 ID + 序号触发（REG_CMD_SEQ），完整命令表、寄存器映射、错误码见 `v3/README.md`。`grbl-learning-master/` 为 GRBL 参考源码（仅供阅读，不参与构建）。

## 开发约定

- **注释与 PRINT 输出为中文**，变量名与关键字为英文。
- 命名规范：全局常量 `ALL_CAPS`（如 `SYS_READY`、`EVENT_HOME`），全局变量 `snake_case`，函数 `PascalCase`（如 `Ecat_Init`），任务函数 `UPPER_SNAKE`（如 `HOME_TASK`）。
- RTBasic 要点（详见 `33.md`）：不区分大小写；块语句以 `END` 结尾；`GLOBAL` 全局变量、`DIM` 文件模块变量、`LOCAL` 局部变量；`$` 前缀表示十六进制。
- 寄存器资源：`TABLE`（float64 大数组）存轨迹数据与结构参数；`MODBUS_REG`（16 位 INT）存命令与状态。地址分配必须遵守 `v2/register_assignment.md`（v3 见 `v3/README.md` 的映射表），新增占用需同步更新文档。
- 新增 FSM 状态时：在配置文件中加状态/事件常量 → 在分发函数中加分支 → 实现 `Handle_SYS_*()` → 确保该状态下所有合法事件均有处理。
- 修改 C 运动学库后需重新编译 `.so` 并重新下载；注意正逆解单位一致性（mm/um 与脉冲的转换，`ENCODER_PER_ROE = 8388608 = 2^23`，丝杠导程 5mm，驱动器电子齿轮比不要与 `UNITS` 重复缩放）。

## 测试策略

项目**没有自动化测试框架**，测试在真实控制器硬件上进行：

- 桩任务函数用 `DELAY` 模拟执行，验证状态机/协议逻辑
- 通过 MODBUS 写入命令/事件，观察 ZDevelop 控制台的 `PRINT` 输出与状态寄存器变化
- 回零、点动、轨迹等功能需连接实际驱动器验证
- 运动学验证：在 ZDevelop 中向 TABLE 写入测试坐标，调用 CFRAME 检查正逆解输出；`frame1000.c` 中 `g_printflag` 控制调试打印

## 安全注意事项

1. **急停（ESTOP）** 在任何状态下都必须可触发，触发后立即停止所有任务并去使能轴。
2. **心跳检测**：上位机与控制器通过心跳寄存器互检，通信超时需进入安全状态。
3. **回零依赖**：笛卡尔空间运动（点动/轨迹）依赖正解绝对位姿，未完成回零前 FSM 必须拒绝这类指令。
4. **驱动器状态**：周期性检查 `DRIVE_STATUS`/`AXISSTATUS`，异常时触发安全响应。
5. **限位**：物理限位开关（`FWD_IN`/`REV_IN`/`DATUM_IN`）应接入并配置检测逻辑。
6. 使用 `SOD_WRITE` 等实时修改驱动器参数的指令时**频率切勿过高**。

## 相关文档

- `RTBasic编程手册V1.1.2.pdf` — RTBasic 官方编程手册（根目录）
- `33.md` — RTBasic 语法与指令学习笔记
- `v2/AGENTS.md` — v2 架构详细文档；`v2/register_assignment.md` — 寄存器分配
- `v3/README.md` — v3 完整设计文档（命令协议、寄存器映射、错误码、GRBL 对照表）
- `command_map.md` — 轨迹指令格式（MOVE/MOVEABS/MOVE_PTABS）
