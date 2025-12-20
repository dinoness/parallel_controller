'' 实现目标：输入连续的位置（轨迹），输出控制电机
DELAY(3000)  '等待驱动器设备上电完成
PRINT "总线通讯周期：",SERVO_PERIOD,"us"  ' 也叫伺服周期

GLOBAL CONST BUS_NODE_NUM = 1  ' 期望连接的设备数
GLOBAL CONST BUS_SLOT = 0  ' 槽位号，默认0
GLOBAL bus_initstate  ' 总线初始化状态
GLOBAL bus_total_axis_num
GLOBAL home_initstate  ' 回零操作

bus_initstate = -1
home_initstate = -1

Ecat_Init()

WHILE (bus_initstate = 0)
    Ecat_Init()
WEND

dim u_j1
CONST PB = 5  ' mm，丝杠导程
CONST ENCODER_PER_ROE = 8388608  ' 2^23

u_j1 = ENCODER_PER_ROE / 360  ' ============UNIT为1°============

BASE(0)
SPEED = 10
ACCEL = 10
DECEL = 10
DPOS = 0
UNITS = u_j1

' 此处有回零

MERGE = ON

' trace config parameters
DIM n_loop
DIM state_data
DIM p_data
DIM trace_loop
CONST size_data = 100
CONST groups_data = 10
' State flag of data
CONST F_DataUpdate = 1
CONST F_DataUsed = 2
CONST F_DataBlank = 3
' Table index
CONST Start_Index = 1000
DIM loop_start_index
DIM loop_end_index
' Motion parameters
CONST n_ticks = 10

FOR n_loop = 1 TO groups_data STEP 1
	MODBUS_REG(n_loop) = F_DataBlank
NEXT

' 给一个初始化完成信号
WHILE 1
	FOR n_loop = 0 TO 2 STEP 1
		p_data = n_loop MOD groups_data
		state_data = MODBUS_REG(p_data)
		WHILE (state_data <> F_DataUpdate)
			state_data = MODBUS_REG(p_data)
		WEND
		
		loop_start_index = Start_Index + n_loop * size_data
		loop_end_index = loop_start_index + size_data - 1
		FOR trace_loop = loop_start_index TO loop_end_index STEP 1
			MOVE_PTABS(n_ticks, TABLE(trace_loop))
		NEXT
		
		MODBUS_REG(p_data) = F_DataUsed
		
	NEXT
WEND
END

' Q1:总线通讯周期和伺服周期
' Q2:


