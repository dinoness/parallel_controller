GLOBAL SUB MANNUAL_JOINT()
    PRINT "Mannual joint."

    LOCAL cmd_start_index
    LOCAL cmd_end_index
    LOCAL cmd_id
    LOCAL speed_level
    LOCAL joint_speed
    LOCAL joint_acc


    BASE(0,1,2,3,4)
    ' ATYPE在总线初始化时就设置
    UNITS = u_j1, u_j2, u_j3, u_j4, u_j5
    dpos = 0,0,0,0,0  '设置关节轴的位置

    data_state = MODBUS_REG(REG_JOINT_CMD_STATE_BEGIN)
    WHILE (data_state <> F_DataUpdate)
		    data_state = MODBUS_REG(REG_JOINT_CMD_STATE_BEGIN)
	WEND

    ' 定位指令
    cmd_start_index = TABLE_JOINT_CMD_BEGIN
    cmd_end_index = cmd_start_index + SIZE_JOINT_CMD - 1

    ' 指令信息
    cmd_id = TABLE(cmd_start_index)
    speed_level = TABLE(cmd_end_index)

    ' 设置运动级数
    IF speed_level = SPEED_L3
        joint_speed = JOINT_L3_SPEED
        joint_acc = JOINT_L3_ACC
    ELSEIF speed_level = 2
        joint_speed = JOINT_L2_SPEED
        joint_acc = JOINT_L2_ACC
    ELSE
        joint_speed = JOINT_L1_SPEED
        joint_acc = JOINT_L1_ACC
    ENDIF

    speed = joint_speed, joint_speed, joint_speed, joint_speed, joint_speed
    accel = joint_acc, joint_acc, joint_acc, joint_acc, joint_acc
    decel = joint_acc, joint_acc, joint_acc, joint_acc, joint_acc


    ' 执行指令
    IF cmd_id = CMD_JOINT_MOVE_REL THEN
        MOVE(TABLE(cmd_start_index+1), TABLE(cmd_start_index+2), TABLE(cmd_start_index+3), TABLE(cmd_start_index+4), TABLE(cmd_start_index+5))
        WAIT IDLE
    ENDIF

    MODBUS_REG(REG_JOINT_CMD_STATE_BEGIN) = F_DataUsed
    MODBUS_REG(REG_EVENT_L1) = EVENT_JOINT_DONE
END SUB