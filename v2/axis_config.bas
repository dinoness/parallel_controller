' 配置运动相关的参数
GLOBAL SUB AXIS_CONGIF()
    CONST LENGTH_UNIT = 1  ' 长度单位转化，1代表mm，1000代表um
    CONST PB = 5 * LENGTH_UNIT  ' 丝杠导程
    CONST ENCODER_PER_ROE = 8388608  ' 2^23

    CONST u_j1 =  ENCODER_PER_ROE / PB  ' 关节1实际1mm or um脉冲数
    CONST u_j2 =  ENCODER_PER_ROE / PB  ' 关节2实际1mm or um脉冲数
    CONST u_j3 =  ENCODER_PER_ROE / PB  ' 关节3实际1mm or um脉冲数
    CONST u_j4 =  ENCODER_PER_ROE / PB  ' 关节4实际1mm or um脉冲数 
    CONST u_j5 =  ENCODER_PER_ROE / PB  ' 关节5实际1mm or um脉冲数 
    ' UNITS为指定运行一个单位需要的脉冲数，之后所有的运动指令都以此为单位
    ' 经过实测，电机运行一圈的脉冲数就是编码器一圈的数值，前提是驱动器中没有设置电子齿轮
    ' 不仅是脉冲轴，总线轴也要设置UNITS

    CONST JOINT_L1_SPEED = 1;
    CONST JOINT_L2_SPEED = 5;
    CONST JOINT_L3_SPEED = 10;
    CONST JOINT_L1_ACC = 2;
    CONST JOINT_L2_ACC = 10;
    CONST JOINT_L3_ACC = 15;
END SUB