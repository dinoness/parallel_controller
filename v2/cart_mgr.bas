GLOBAL SUB CART()
    BASE(6,7,8,9,10)
    atype = 0,0,0,0,0  ' 取0设置为虚拟轴
    speed = 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT, 5 * LENGTH_UNIT
    UNITS= 1,1,1,1,1         '运动精度，要提前设置，中途不能变化
    TABLE(ROBO_PARA_START_ID,u_j1,u_j2,u_j3,u_j4,u_j5)  ' 将参数写入到TABLE中，这样C配置文件中会读取对应的参数，第一个参数是指数据的起始位置

    MERGE = ON

    ' 逆解模式
    BASE(0,1,2,3,4)
    CONNFRAME(1000,robo_para_start_id,6,7,8,9,10)
    WAIT LOADED  '' 等待加载完成
END SUB