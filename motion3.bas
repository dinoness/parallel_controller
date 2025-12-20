' for home1.bas
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

' 修改UNIT后记得在home回零位的文件中也改响应的值
u_j1 = ENCODER_PER_ROE / 360  ' ============UNIT为1°============

BASE(0)
SPEED = 10
ACCEL = 10
DECEL = 10
DPOS = 0
UNITS = u_j1

home_single_axis()

END

