DELAY(3000)  '�ȴ��������豸�ϵ����
PRINT "����ͨѶ���ڣ�",SERVO_PERIOD,"us"

GLOBAL CONST BUS_NODE_NUM = 1  ' �������ӵ��豸��
GLOBAL CONST BUS_SLOT = 0  ' ��λ�ţ�Ĭ��0
GLOBAL bus_initsate ' ���߳�ʼ��״̬
GLOBAL bus_total_axis_num

bus_initsate = -1


Ecat_Init()

WHILE (bus_initsate = 0)
    Ecat_Init()
WEND


dim u_j1      '�ؽ�1ʵ��1mm������
CONST PB = 5  ' mm��˿�ܵ���
CONST ENCODER_PER_ROE = 8388608  ' 2^23

u_j1 = ENCODER_PER_ROE / 360

BASE(0)
SPEED = 100
ACCEL = 20
DECEL = 20
DPOS = 0
UNITS = u_j1

MERGE = ON

MOVE(360)
WAIT IDLE
? *DPOS

