' 需要测试多轴回零的逻辑
GLOBAL SUB home_robot()
    IF bus_initstate <> 1 THEN
        PRINT "总线未初始化"
        END SUB
    ENDIF

    IF bus_total_axis_num <> 5 THEN
        PRINT "轴数不为5"
        home_initstate = 0
        END SUB
    ENDIF

    dim i_axis
    FOR i_axis = 0 TO 2 STEP 1
        BASE(i_axis)
        creep = 1 * LENGTH_UNIT  ' 回零反找时的速度
        speed = 3 * LENGTH_UNIT
        accel = 10 * LENGTH_UNIT
        decel = 10 * LENGTH_UNIT
        DATUM(21, 29)  ' 29
    NEXT

	FOR i_axis = 3 TO 4 STEP 1
		BASE(i_axis)
		creep = 1 * LENGTH_UNIT  ' 回零反找时的速度
		speed = 3 * LENGTH_UNIT
		accel = 10 * LENGTH_UNIT
		decel = 10 * LENGTH_UNIT
		DATUM(21, 17)
	NEXT

    
    WAIT IDLE

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