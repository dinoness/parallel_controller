'' 该程序作用是回零位，常用于上电后的操作
'' 常规思路：电机先高速运动，需要原点传感器，找到之后回退，在低速靠近，检测到跳变后再停止，设此时的位置为0
'' 可能的问题：多轴的耦合，传感器的精度
'' 思路2：使用绝对值编码器，手动调好零位后，设置Z信号为0
'' 回零方式通过 6098h来设置（优先考虑29），待选模式：11-14，区别点在于Z信号与原点开关的关系(如何修改？属于6000h对象字典)（如何设置Z信号？）
'' 思路3：驱动器+限位传感器
'' 硬件上限位NPN传感器信号接到驱动器上（正负/高低电平的逻辑？）
'' 回零方式通过 6098h来设置（优先考虑29），待选模式：27反向逼近+下降沿，28反向逼近+上升沿，29正向逼近+上升沿停机，30正向逼近+下降沿停机，（正反方向是怎么确定的？）
'' 电机转向方式，修改H02.02

'' =======控制器相关=======
'' 多轴回零时，需要每个轴都使用 DATUM 指令
'' 总线控制器使用控制器找原点模式完成后，需要手动清零 MPOS
'' DATUM 指令后不能接绝对指令和mover 指令

'' Q1:6000h组参数修改
'' A1:6098h直接通过DATUM指令的Mode2设置
'' Q2:Z信号设置
'' A2:
'' Q3:使用29模式回零时，在遇到负限位时，驱动器会直接报错E630.0，而不会转变成正向运动。其中运动指令时通过控制器发送的
'' A3:因为传感器安装在了机械限制外

'' 请在此前执行总线初始化
GLOBAL SUB home_single_axis()
    IF bus_initstate <> 1 THEN
        PRINT "总线未初始化"
        END SUB
    ENDIF

    BASE(0)
    creep = 1  ' 回零反找时的速度
    speed = 3
    accel = 10
    decel = 10
    
    '' 按照控制器回零
    DATUM(21, 29)  ' 21总线模式，29表示具体的回零策略，依据6098h的设定值填写
	'' 17，以负限位作为停止点
	
	WAIT IDLE


    ' TABLE(0) = DRIVE_STATUS
    ' home_initstate = 0  ' 0表示回零没好
    ' IF READ_BIT2(10, TABLE(0)) THEN
    '     IF READ_BIT2(12, TABLE(0)) THEN
    '         PRINT "Home Finish"
    '         home_initstate = 1
    '     ENDIF
    ' ENDIF
	' PRINT "home_initstate:"home_initstate

    '' ========================不知道直接赋值给变量行不行========================
    TABLE(500) = DRIVE_STATUS
    home_initstate = 0  ' 0表示回零没好
    IF READ_BIT2(10, TABLE(500)) THEN
        IF READ_BIT2(12, TABLE(500)) THEN
            PRINT "Home Finish"
            home_initstate = 1
        ENDIF
    ENDIF
	PRINT "home_initstate:"home_initstate


END SUB

' 需要测试多轴回零的逻辑
GLOBAL SUB home_robot()
    IF bus_initstate <> 1 THEN
        PRINT "总线未初始化"
        END SUB
    ENDIF

    ' === TO DO ===
    dim i_axis
    FOR i_axis = 0 TO (bus_total_axis_num - 1) STEP 1
        BASE(i_axis)
        creep = 1  ' 回零反找时的速度
        speed = 3
        accel = 10
        decel = 10
        DATUM(21, 29)
    NEXT

    WAIT IDLE

    '' ========================如果有多个轴，drive_status是什么样的========================
	'' ========================下面这段代码好像没什么用========================
    home_initstate = 0
    'dim num_home_axis = 0
    dim home_state
    FOR i_axis = 0 TO (bus_total_axis_num - 1) STEP 1
        TABLE(500) = DRIVE_STATUS(i_axis)
        IF READ_BIT2(10, TABLE(500)) THEN
            IF READ_BIT2(12, TABLE(500)) THEN
                PRINT "Home Finish"
                home_initstate = 1
            ENDIF
        ENDIF
    NEXT

    PRINT "home_initstate:"home_initstate

END SUB