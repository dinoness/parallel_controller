controller/
├─ main.bas                   系统主状态机、任务启动、模式管理
├─ global_def.bas             全局常量、状态码、错误码、寄存器地址定义
├─ ecat_mgr.bas               EtherCAT扫描、轴映射、驱动清错、轴使能
├─ axis_config.bas            轴类型、UNITS、速度、加速度、软限位、限位输入配置
├─ param_mgr.bas              参数加载、参数校验、TABLE/FLASH/VR参数同步
├─ robot_model.c              并联机器人逆解、正解、工作空间检查、奇异/越界判断
├─ home_mgr.bas               多轴回零状态机
├─ manual_joint_mgr.bas       单独调整每个物理轴
├─ cart_jog_mgr.bas           笛卡尔方向点动
├─ traj_executor.bas          轨迹缓冲读取、MOVE_PTABS执行、暂停恢复
├─ sensor_mgr.bas             外部传感器采集、滤波、标定
├─ closed_loop_mgr.bas        基于传感器的闭环控制
├─ safety_mgr.bas             急停、限位、报警、watchdog、越界检查
└─ status_report.bas          状态反馈、错误码、当前位置、传感器值、调试信息