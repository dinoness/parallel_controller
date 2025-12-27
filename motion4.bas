' 用于测试机械手，运动，数据相关 2轴
' ============= TO DO =============
' 1. 测试多轴回零（就是在循环中给依次给回零指令）- Verified
' 2. 测试虚拟轴脉冲数意义
    '- 将外界指令转化为计算值，如果轨迹已经是mm，则设置1即可
    '- 运动精度？
' 3. 测试机械手解算有效性 - 五轴算法可以在上位机中验证
	'- 逻辑：初始化的时候会调用正解函数，相当于计算初始坐标，之后在调用逆解函数。
	'- 正解函数怎么写还要再考虑
' 4. 测试轨迹/指令传输有效性 - Verifieds
' 5. 测试运动指令对于机械手的有效性 - Verified
' 6. 测试机械手参数设置的正确性 - Verified
	'- 可以通过RTSys中的寄存器工具直接读取数据，不用通过PRINT读取
' 7. 测试矢量矩阵函数库的可用性


DELAY(3000)  '等待驱动器设备上电完成
PRINT "总线通讯周期：",SERVO_PERIOD,"us"  ' 也叫伺服周期

GLOBAL CONST BUS_NODE_NUM = 2  ' 期望连接的设备数
GLOBAL CONST BUS_SLOT = 0  ' 槽位号，默认0
GLOBAL bus_initstate  ' 总线初始化状态
GLOBAL bus_total_axis_num
GLOBAL home_initstate  ' 回零操作
GLOBAL CONST ROBO_PARA_START_ID = 0  ' 参数起始id

bus_initstate = -1
home_initstate = -1


Ecat_Init()

WHILE (bus_initstate = 0)
    Ecat_Init()
WEND

CONST PB = 5  ' mm，丝杠导程
CONST ENCODER_PER_ROE = 8388608  ' 2^23

dim u_j1
dim u_j2
dim u_j3
dim u_j4
dim u_j5


u_j1 =  ENCODER_PER_ROE / PB  ' 关节1实际1mm脉冲数
u_j2 =  ENCODER_PER_ROE / PB  ' 关节2实际1mm脉冲数
u_j3 =  ENCODER_PER_ROE / PB  ' 关节3实际1mm脉冲数
u_j4 =  ENCODER_PER_ROE / PB  ' 关节4实际1mm脉冲数 
u_j5 =  ENCODER_PER_ROE / PB  ' 关节5实际1mm脉冲数  ' ============UNIT为1mm============

'' ==========  定义几何尺寸  ==========
rob_para_config1(5)

'' ==========  定义机械手  ==========
DEFINE_CFRAME  1000,BUS_NODE_NUM,0,0,0    'framenum, totalaxises, axises_aux,  max_attitudes,  rotatetype

'' ==========  设置关节轴  ==========
BASE(0,1)
' ATYPE在总线初始化时就设置
UNITS = u_j1, u_j2

'' ==========  回零位  ==========
home_robot()
IF home_initstate = 0 THEN
    home_robot()
ENDIF

dpos=0,0  '设置关节轴的位置
speed=5,5
accel=10,10
decel=10,10

'' 虚拟轴设置
BASE(6,7)
atype = 0,0  ' 取0设置为虚拟轴
speed = 5,5  
UNITS= 1,1   '运动精度，要提前设置，中途不能变化

TABLE(ROBO_PARA_START_ID,u_j1,u_j2,u_j3,u_j4,u_j5)  ' 将参数写入到TABLE中，这样C配置文件中会读取对应的参数，第一个参数是指数据的起始位置，尺寸数据已通过rob_para_config1写入

'' 插补设置
MERGE = ON

'' 逆解模式
BASE(0,1)
CONNFRAME(1000,robo_para_start_id,6,7)
WAIT LOADED  '' 等待加载完成
PRINT "逆解模式"

BASE(6,7)  ' 控制虚拟轴
' ============ move test ============
'MOVEABS(20,20)
'WAIT IDLE
'PRINT *DPOS
'MOVEABS(0,0)
'WAIT IDLE
'PRINT *DPOS
'MOVE_PTABS(1000,1,1)
'MOVE_PTABS(1000,2,2)
'WAIT IDLE
'PRINT *DPOS
' ============ move test ============

' ============ 运动指令部分 ============
' trace config parameters
DIM n_loop  '总循环次数
DIM data_state  ' 数据状态
DIM cur_group_id  ' 当前的缓冲数据组
DIM i_loop  ' 循环变量
CONST CmdSize = 7  ' 一条指令的数据个数
CONST DataGroupNum = 10  ' 数据块缓冲数
CONST DataGroupSize = 100  ' 数据块中的数据数
CONST DataBlockSize = DataGroupSize*CmdSize  ' 一个缓冲块中的数据总数

' State flag of data
CONST F_DataUpdate = 1
CONST F_DataUsed = 2
CONST F_DataBlank = 3
' Table index
CONST Start_Index = 1000
DIM loop_start_index
DIM loop_end_index
' Motion parameters
DIM cmd_id
CONST n_ticks = 100  

FOR n_loop = 0 TO (DataGroupNum - 1) STEP 1
	MODBUS_REG(n_loop) = F_DataBlank
NEXT

PRINT "Go into loop."
n_loop = 0
WHILE 1
    cur_group_id = n_loop MOD DataGroupNum
    data_state = MODBUS_REG(cur_group_id)
	PRINT "cur_group_id = " cur_group_id
	PRINT "data_state = "data_state
	
    WHILE (data_state <> F_DataUpdate)
		data_state = MODBUS_REG(cur_group_id)
	WEND

    loop_start_index = Start_Index + cur_group_id * DataBlockSize
    loop_end_index = loop_start_index + DataBlockSize - 1
	'PRINT "loop_start_index" loop_start_index
	
'    FOR i_loop = loop_start_index TO loop_end_index STEP CmdSize
'        cmd_id = TABLE(i_loop)
'        IF cmd_id = 1 THEN
'            MOVE(TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5))
'            PRINT "MOVE"
'            PRINT cmd_id,TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5), TABLE(i_loop+6)
'        ELSEIF cmd_id = 2 THEN
'            ' MOVEABS(TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5))
'            PRINT "MOVEABS"
'            PRINT cmd_id,TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5), TABLE(i_loop+6)
'        ELSEIF cmd_id = 10 THEN
'            ' MOVE_PTABS(TABLE(i_loop+6),TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5))
'            PRINT "MOVE_PTABS"
'            PRINT cmd_id,TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5), TABLE(i_loop+6)
'        ELSE
'            'RAPIDSTOP(1)
'			PRINT "Motion stopped."
'			PRINT cmd_id,TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5), TABLE(i_loop+6)
'        ENDIF
'    NEXT
	PRINT "loop_start_index = ", loop_start_index
	PRINT "loop_end_index = ", loop_end_index


	i_loop = loop_start_index
	WHILE i_loop < loop_end_index

		'PRINT "i_loop = " i_loop
		'PRINT cmd_id,TABLE(i_loop+1)
        cmd_id = TABLE(i_loop)
        IF cmd_id = 1 THEN
            MOVE(TABLE(i_loop+1), TABLE(i_loop+2))
			WAIT IDLE
            'PRINT "MOVE"
        ELSEIF cmd_id = 2 THEN
            MOVEABS(TABLE(i_loop+1), TABLE(i_loop+2))
			WAIT IDLE
            'PRINT "MOVEABS"
        ELSEIF cmd_id = 10 THEN
            MOVE_PTABS(TABLE(i_loop+6),TABLE(i_loop+1), TABLE(i_loop+2))
            'PRINT "MOVE_PTABS"
            'PRINT cmd_id,TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5), TABLE(i_loop+6)
        ELSE
            'RAPIDSTOP(1)
			'PRINT "Motion stopped."
			'PRINT cmd_id,TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5), TABLE(i_loop+6)
        ENDIF

		i_loop = i_loop + CmdSize
	WEND
	'PRINT *DPOS
	'PRINT "TABLE data start index "  loop_start_index
	'PRINT *TABLE(loop_start_index, 100)

    n_loop = n_loop + 1
	'EXIT WHILE
WEND
PRINT "Motion4 Over."

END
