''==========  EtherCAT通讯  ==========
DELAY(3000)  '等待驱动器设备上电完成
PRINT "总线通讯周期：",SERVO_PERIOD,"us"

GLOBAL CONST BUS_NODE_NUM = 5  ' 期望连接的设备数
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



'' ============================================
'' ==========     配置/初始化部分     ==========
'' ============================================
'' ==========  设置电机参数  ==========
CONST PB = 5  ' mm，丝杠导程
CONST ENCODER_PER_ROE = 8388608  ' 2^23

dim u_j1 =  ENCODER_PER_ROE / PB  ' 关节1实际1mm脉冲数
dim u_j2 =  ENCODER_PER_ROE / PB  ' 关节2实际1mm脉冲数
dim u_j3 =  ENCODER_PER_ROE / PB  ' 关节3实际1mm脉冲数
dim u_j4 =  ENCODER_PER_ROE / PB  ' 关节4实际1mm脉冲数 
dim u_j5 =  ENCODER_PER_ROE / PB  ' 关节5实际1mm脉冲数 
' UNITS为指定运行一个单位需要的脉冲数，之后所有的运动指令都以此为单位
' 经过实测，电机运行一圈的脉冲数就是编码器一圈的数值，前提是驱动器中没有设置电子齿轮
' 不仅是脉冲轴，总线轴也要设置UNITS


'' ==========  定义几何尺寸  ==========
rob_para_config1(ROBO_PARA_START_ID, BUS_NODE_NUM)


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


dpos=0,0,0,0,0  '设置关节轴的位置
speed=100,100,100,100,100
accel=1000,1000,1000,1000,1000
decel=1000,1000,1000,1000,1000


'' 虚拟轴设置
BASE(6,7,8,9,10)
atype = 0,0,0,0,0  ' 取0设置为虚拟轴
speed = 100,100,100,100,100  ' =====================虚拟轴的单位是什么意思??=====================
' =====================整个两轴的试试??=====================
UNITS= 1000,1000,1000,1000,1000         '运动精度，要提前设置，中途不能变化

''======================== TO DO 配合C文件写入参数========================''
TABLE(ROBO_PARA_START_ID,u_j1,u_j2,u_j3,u_j4,u_j5)  ' 将参数写入到TABLE中，这样C配置文件中会读取对应的参数，第一个参数是指数据的起始位置



'' 插补设置
MERGE = ON
''======================== TO DO 插补的其他设置（或许用不到）========================''
' CORNER_MODE = 2
' DECEL_ANGLE = 15 * (PI / 180)
' STOP_ANGLE = 45 * (PI / 180)



'' 逆解模式
BASE(0,1,2,3,4)
CONNFRAME(1000,robo_para_start_id,6,7,8,9,10,11)
WAIT LOADED  '' 等待加载完成


'' ============================================
'' ==========        运动部分        ==========
'' ============================================
'' 逆解状态下，只要move虚拟轴就可以了？


BASE(6,7,8,9,10,11)  ' 控制虚拟轴
''======================== TO DO 接收上位机发来的数据，并使用MOVE等运动指令========================''



''======================== TO DO 驱动器模式设置========================''
' DRIVE_TORQUE 获取驱动器力矩