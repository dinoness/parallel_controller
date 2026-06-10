GLOBAL SUB MANNUAL_JOINT()
    PRINT "Mannual joint."

    BASE(0,1,2,3,4)
    ' ATYPE在总线初始化时就设置
    UNITS = u_j1, u_j2, u_j3, u_j4, u_j5
    dpos = 0,0,0,0,0  '设置关节轴的位置



    LOCAL n_loop  '总循环次数
    LOCAL data_state  ' 数据状态
    LOCAL cur_group_id  ' 当前的缓冲数据组
    LOCAL cmd_id
    LOCAL cmd_start_index
    LOCAL cmd_end_index
    LOCAL speed_level

    FOR n_loop = REG_JOINT_CMD_STATE_BEGIN TO (REG_JOINT_CMD_STATE_BEGIN + NUM_JOINT_DATA_GROUP) STEP 1
	    MODBUS_REG(n_loop) = F_DataBlank
    NEXT

    ' 这里可以加一个信号回传，说明准备完成=======================

    n_loop = 0
    WHILE 1
        cur_group_id = n_loop MOD NUM_JOINT_DATA_GROUP
        data_state = MODBUS_REG(cur_group_id + REG_JOINT_CMD_STATE_BEGIN)

        WHILE (data_state <> F_DataUpdate)
		    data_state = MODBUS_REG(cur_group_id + REG_JOINT_CMD_STATE_BEGIN)
	    WEND

        ' 定位指令
        cmd_start_index = TABLE_JOINT_CMD_BEGIN + cur_group_id * JOINT_CMD_SIZE
        cmd_end_index = loop_start_index + JOINT_CMD_SIZE - 1

        cmd_id = TABLE(cmd_start_index)
        speed_level = TABLE(cmd_end_index)


        ' 设置运动级数
        LOCAL joint_speed
        LOCAL joint_acc
        IF speed_level = 3
            joint_speed = JOINT_L3_SPEED * LENGTH_UNIT
            joint_acc = JOINT_L3_ACC * LENGTH_UNIT
        ELSEIF speed_level = 2
            joint_speed = JOINT_L2_SPEED * LENGTH_UNIT
            joint_acc = JOINT_L2_ACC * LENGTH_UNIT
        ELSE
            joint_speed = JOINT_L1_SPEED * LENGTH_UNIT
            joint_acc = JOINT_L1_ACC * LENGTH_UNIT
        ENDIF
        
        speed = joint_speed, joint_speed, joint_speed, joint_speed, joint_speed
        accel = joint_acc, joint_acc, joint_acc, joint_acc, joint_acc
        decel = joint_acc, joint_acc, joint_acc, joint_acc, joint_acc


        ' 执行指令
        IF cmd_id = CMD_JOINT_MOVE_REL THEN
            MOVE(TABLE(cmd_start_index+1), TABLE(cmd_start_index+2), TABLE(cmd_start_index+3), TABLE(cmd_start_index+4), TABLE(cmd_start_index+5))
            WAIT IDLE
        ENDIF

        MODBUS_REG(cur_group_id) = F_DataUsed
    WEND
END SUB