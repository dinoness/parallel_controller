DELAY(3000)  '等待驱动器设备上电完成
PRINT "总线通讯周期：",SERVO_PERIOD,"us"

GLOBAL CONST BUS_NODE_NUM = 5  ' 期望连接的设备数
GLOBAL CONST BUS_SLOT = 0  ' 槽位号，默认0
GLOBAL CONST ROBO_PARA_START_ID = 0  ' 参数起始id



' 系统状态变量
GLOBAL system_state
GLOBAL motion_mode
GLOBAL motion_lock
GLOBAL safety_state
GLOBAL active_task
GLOBAL last_cmd_seq
GLOBAL cmd_id
GLOBAL bus_initstate  ' 总线初始化状态
GLOBAL bus_total_axis_num
GLOBAL home_initstate  ' 回零操作

GLOBAL_DEF()
REG_CLEAR()
'========================================================
' 系统状态初始化
'========================================================
system_state = SYS_BOOT
motion_mode = MODE_IDLE
motion_lock = MODE_IDLE
active_task = -1
safety_state = 0

MODBUS_REG(REG_SYSTEM_STATE) = system_state
MODBUS_REG(REG_MOTION_MODE) = motion_mode
' MODBUS_REG(REG_CMD_STATE) = CMD_STATE_IDLE
MODBUS_REG(REG_CMD_ERROR) = ERR_OK
last_cmd_seq = MODBUS_REG(REG_CMD_SEQ)


'========================================================
' EtherCAT通讯
'========================================================
system_state = SYS_BUS_INIT
MODBUS_REG(REG_SYSTEM_STATE) = system_state


bus_initstate = -1

Ecat_Init()
WHILE (bus_initstate = 0)
    Ecat_Init()
WEND


system_state = SYS_SERVO_READY
MODBUS_REG(REG_SYSTEM_STATE) = SYS_SERVO_READY


'========================================================
' 运动参数配置
'========================================================
'' ==========  设置运动相关参数  ==========
AXIS_CONGIF()

'' ==========  定义几何尺寸  ==========
rob_para_config1(bus_total_axis_num)

'' ==========  定义机械手  ==========
DEFINE_CFRAME  1000,BUS_NODE_NUM,0,0,0    'framenum, totalaxises, axises_aux,  max_attitudes,  rotatetype



'========================================================
' 主循环
'========================================================
DIM cur_event
WHILE 1

    ' 2. 获取新事件
    cur_event = CHECK_EVENT(REG_EVENT_BEGIN, MAX_EVENT_LEVEL)

    ' 3. 监控当前任务
    SMF_DISPATCH(system_state, cur_event)

    ' 4. 写状态反馈
    MODBUS_REG(REG_SYSTEM_STATE) = system_state' 系统状态
    MODBUS_REG(REG_MOTION_MODE) = motion_mode  ' 运动模式
    MODBUS_REG(REG_ACTIVE_TASK) = active_task  ' 当前正在执行的任务

    DELAY(100)

WEND