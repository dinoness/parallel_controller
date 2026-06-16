GLOBAL SUB ROBO_PARA_CONFIG1(num_axis)
    CONST R1 = 550 * LENGTH_UNIT
    CONST R2 = 500 * LENGTH_UNIT
    CONST H = 0 * LENGTH_UNIT
    CONST r_1 = 100 * LENGTH_UNIT
    CONST r_2 = 80 * LENGTH_UNIT
    CONST h_ = 10 * LENGTH_UNIT


    ' static plant(world coordiant)
    ' data structure: 0-x,1-y,2-z
    dim b1(3)
    dim b2(3)
    dim b3(3)
    dim b4(3)
    dim b5(3)



    ' 已经乘过单位转换了，这里又乘不就转两次了吗==========================
    ' 替换为倒置后支链的映射关系记得改
    b1(0, R1 * COS(PI/2) * LENGTH_UNIT,   R1 * SIN(PI/2) * LENGTH_UNIT,   0 * LENGTH_UNIT)
    b2(0, R1 * COS(7*PI/6) * LENGTH_UNIT, R1 * SIN(7*PI/6) * LENGTH_UNIT, 0 * LENGTH_UNIT)
    b3(0, R1 * COS(-PI/6) * LENGTH_UNIT,  R1 * SIN(-PI/6) * LENGTH_UNIT,  0 * LENGTH_UNIT)
    b4(0, R2 * COS(5*PI/6) * LENGTH_UNIT,   R2 * SIN(5*PI/6) * LENGTH_UNIT,   H * LENGTH_UNIT)
    b5(0, R2 * COS(PI/6) * LENGTH_UNIT, R2 * SIN(PI/6) * LENGTH_UNIT, H * LENGTH_UNIT)


    ' movable plant(movable plant coordiant)
    ' data structure: 0-x,1-y,2-z
    dim m1(3)
    dim m2(3)
    dim m3(3)
    dim m4(3)
    dim m5(3)


    m1(0, r_1 * COS(PI/2) * LENGTH_UNIT,   r_1 * SIN(PI/2) * LENGTH_UNIT,   0 * LENGTH_UNIT)
    m2(0, r_1 * COS(7*PI/6) * LENGTH_UNIT, r_1 * SIN(7*PI/6) * LENGTH_UNIT, 0 * LENGTH_UNIT)
    m3(0, r_1 * COS(-PI/6) * LENGTH_UNIT,  r_1 * SIN(-PI/6) * LENGTH_UNIT,  0 * LENGTH_UNIT)
    m4(0, r_2 * COS(5*PI/6) * LENGTH_UNIT, r_2 * SIN(5*PI/6) * LENGTH_UNIT, h_ * LENGTH_UNIT)
    m5(0, r_2 * COS(PI/6) * LENGTH_UNIT,   r_2 * SIN(PI/6) * LENGTH_UNIT,   h_ * LENGTH_UNIT)


    dim limb0(5)
    'limb0(0, 714.510315 * LENGTH_UNIT, 714.510315 * LENGTH_UNIT, 714.510315 * LENGTH_UNIT, 688.058838 * LENGTH_UNIT, 688.058838 * LENGTH_UNIT)
    limb0(0, 714.5104370117 * LENGTH_UNIT, 714.5114135742 * LENGTH_UNIT, 714.5114135742 * LENGTH_UNIT, 688.0593261719 * LENGTH_UNIT, 688.0593261719 * LENGTH_UNIT)


    dim config_start_id
    config_start_id = TABLE_ROBO_PARA_BEGIN + num_axis
    TABLE(config_start_id, b1(0), b1(1), b1(2), b2(0), b2(1), b2(2), b3(0), b3(1), b3(2), b4(0), b4(1), b4(2), b5(0), b5(1), b5(2))

    config_start_id = config_start_id + 15
    TABLE(config_start_id, m1(0), m1(1), m1(2), m2(0), m2(1), m2(2), m3(0), m3(1), m3(2), m4(0), m4(1), m4(2), m5(0), m5(1), m5(2))

    config_start_id = config_start_id + 15
    TABLE(config_start_id, limb0(0), limb0(1), limb0(2), limb0(3), limb0(4))

    config_start_id = config_start_id + 5
    TABLE(config_start_id) = LENGTH_UNIT


    PRINT "para config over."

END SUB  ' 注意是END SUB


' 进入机器人模式
GLOBAL SUB ROBOT_MODE()
    BASE(6,7,8,9,10)
    atype = 0,0,0,0,0  ' 取0设置为虚拟轴
    speed = 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT
    UNITS= 1,1,1,1,1         '运动精度，要提前设置，中途不能变化
    TABLE(TABLE_ROBO_PARA_BEGIN,u_j1,u_j2,u_j3,u_j4,u_j5)  ' 将参数写入到TABLE中，这样C配置文件中会读取对应的参数，第一个参数是指数据的起始位置

    MERGE = ON

    ' 逆解模式
    BASE(0,1,2,3,4)
    CONNFRAME(1000,TABLE_ROBO_PARA_BEGIN,6,7,8,9,10)
    WAIT LOADED  '' 等待加载完成
END SUB