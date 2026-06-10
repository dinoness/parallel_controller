''==========  EtherCAT通讯  ==========
DELAY(3000)  '等待驱动器设备上电完成
PRINT "总线通讯周期：",SERVO_PERIOD,"us"

GLOBAL CONST BUS_NODE_NUM = 5  ' 期望连接的设备数
GLOBAL CONST BUS_SLOT = 0  ' 槽位号，默认0
GLOBAL bus_initstate  ' 总线初始化状态
GLOBAL bus_total_axis_num
GLOBAL home_initstate  ' 回零操作
GLOBAL CONST ROBO_PARA_START_ID = 0  ' 参数起始id
GLOBAL CONST LENGTH_UNIT = 1  ' 长度单位转化，1代表mm，1000代表um

bus_initstate = -1
home_initstate = -1

Ecat_Init()

WHILE (bus_initstate = 0)
    Ecat_Init()
WEND



'' ============================================
'' ==========     配置/初始化部分     ==========
'' ============================================
'' ==========  设置电机参数  ==========
CONST PB = 5 * LENGTH_UNIT  ' 丝杠导程
CONST ENCODER_PER_ROE = 8388608  ' 2^23

DIM u_j1
DIM u_j2
DIM u_j3
DIM u_j4
DIM u_j5
u_j1 =  ENCODER_PER_ROE / PB  ' 关节1实际1mm or um脉冲数
u_j2 =  ENCODER_PER_ROE / PB  ' 关节2实际1mm or um脉冲数
u_j3 =  ENCODER_PER_ROE / PB  ' 关节3实际1mm or um脉冲数
u_j4 =  ENCODER_PER_ROE / PB  ' 关节4实际1mm or um脉冲数 
u_j5 =  ENCODER_PER_ROE / PB  ' 关节5实际1mm or um脉冲数 
' UNITS为指定运行一个单位需要的脉冲数，之后所有的运动指令都以此为单位
' 经过实测，电机运行一圈的脉冲数就是编码器一圈的数值，前提是驱动器中没有设置电子齿轮
' 不仅是脉冲轴，总线轴也要设置UNITS


'' ==========  定义几何尺寸  ==========
rob_para_config1(bus_total_axis_num)


'' ==========  定义机械手  ==========
DEFINE_CFRAME  1000,BUS_NODE_NUM,0,0,0    'framenum, totalaxises, axises_aux,  max_attitudes,  rotatetype


'' ==========  设置关节轴  ==========
BASE(0,1,2,3,4)
' ATYPE在总线初始化时就设置
UNITS = u_j1, u_j2, u_j3, u_j4, u_j5


'' ==========  回零位  ==========
home_robot()
IF home_initstate = 0 THEN
    home_robot()
ENDIF


dpos = 0,0,0,0,0  '设置关节轴的位置
'dpos=714.510315 * LENGTH_UNIT, 714.510315 * LENGTH_UNIT, 714.510315 * LENGTH_UNIT, 688.058838 * LENGTH_UNIT, 688.058838 * LENGTH_UNIT
speed = 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT
accel = 10 * LENGTH_UNIT, 10 * LENGTH_UNIT, 10 * LENGTH_UNIT, 10 * LENGTH_UNIT, 10 * LENGTH_UNIT
decel = 10 * LENGTH_UNIT, 10 * LENGTH_UNIT, 10 * LENGTH_UNIT, 10 * LENGTH_UNIT, 10 * LENGTH_UNIT


'' 虚拟轴设置
BASE(6,7,8,9,10)
atype = 0,0,0,0,0  ' 取0设置为虚拟轴
speed = 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT
UNITS= 1,1,1,1,1         '运动精度，要提前设置，中途不能变化
TABLE(ROBO_PARA_START_ID,u_j1,u_j2,u_j3,u_j4,u_j5)  ' 将参数写入到TABLE中，这样C配置文件中会读取对应的参数，第一个参数是指数据的起始位置



'' 插补设置
MERGE = ON
''======================== TO DO 插补的其他设置（或许用不到）========================''
' CORNER_MODE = 2
' DECEL_ANGLE = 15 * (PI / 180)
' STOP_ANGLE = 45 * (PI / 180)


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' 逆解模式
BASE(0,1,2,3,4)
CONNFRAME(1000,robo_para_start_id,6,7,8,9,10)
WAIT LOADED  '' 等待加载完成


'' ============================================
'' ==========        运动部分        ==========
'' ============================================
BASE(6,7,8,9,10)  ' 控制虚拟轴


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

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
PRINT "Go into loop."
n_loop = 0
'' 接收上位机发来的数据，并执行''
WHILE 1
   cur_group_id = n_loop MOD DataGroupNum
   data_state = MODBUS_REG(cur_group_id)
	
    WHILE (data_state <> F_DataUpdate)
		data_state = MODBUS_REG(cur_group_id)
	WEND

   loop_start_index = Start_Index + cur_group_id * DataBlockSize
   loop_end_index = loop_start_index + DataBlockSize - 1
	'PRINT "loop_start_index" loop_start_index

	i_loop = loop_start_index
	WHILE i_loop < loop_end_index
        cmd_id = TABLE(i_loop)

        ' TABLE内容查看建议通过RTSys查看
        IF cmd_id = 1 THEN
            MOVE(TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5))
			WAIT IDLE
            'PRINT "MOVE"
        ELSEIF cmd_id = 2 THEN
            MOVEABS(TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5))
			WAIT IDLE
            'PRINT "MOVEABS"
        ELSEIF cmd_id = 10 THEN
            MOVE_PTABS(TABLE(i_loop+6),TABLE(i_loop+1), TABLE(i_loop+2), TABLE(i_loop+3), TABLE(i_loop+4), TABLE(i_loop+5))
            'PRINT "MOVE_PTABS"
        ELSE
            'RAPIDSTOP(1)
			PRINT "Motion stopped."
        ENDIF

        i_loop = i_loop + CmdSize  ' 移到下一条指令
    WEND

    MODBUS_REG(cur_group_id) = F_DataUsed

	'PRINT *DPOS

    n_loop = n_loop + 1  ' 记录循环次数
WEND
'BASE(0,1,2,3,4)
'MOVE(10000,30000,50000,70000,90000)
' MOVEABS(0,30*LENGTH_UNIT,-600*LENGTH_UNIT,0,0)
' WAIT IDLE
' MOVE_PTABS(50,0.1*LENGTH_UNIT,30.1*LENGTH_UNIT,-600*LENGTH_UNIT,0,0)
' ?*DPOS
PRINT "Motion1 Over."
END


' DRIVE_TORQUE 获取驱动器力矩