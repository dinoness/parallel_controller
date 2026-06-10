' 事件获取
GLOBAL SUB CHECK_EVENT(event_register_begin, event_level_size)
DIM i
DIM new_event
FOR i = 0 TO event_level_size STEP 1
    new_event = MODBUS_REG(i + event_register_begin)
    IF new_event <> EVENT_IDLE
        MODBUS_REG(i + event_register_begin) = EVENT_IDLE
        RETURN new_event
    ENDIF
NEXT

RETURN EVENT_IDLE

END SUB


' 事件分发
GLOBAL SUB SMF_DISPATCH(current_state, event)
    IF current_state = SYS_SERVO_READY THEN
        Handle_SYS_SERVO_READY(event)
    ELSEIF current_state = SYS_HOMING THEN
        Handle_SYS_HOMING(event)
    ELSEIF current_state = SYS_READY THEN
        Handle_SYS_READY(event)
    ELSEIF current_state = SYS_RUNNING THEN
        Handle_SYS_RUNNING(event)
    ELSE
        Handle_SYS_ERROR(event)
    ENDIF


END SUB


SUB Handle_SYS_SERVO_READY(event)
    IF event = EVENT_HOME THEN
        ' 执行回零操作
        ' 完成后状态切换到HOMING
    ELSEIF event = EVENT_JOINT THEN
        ' 执行单轴运动
        ' 完成后状态切换到SERVO_READY
    ELSE
        ' 输出未回零
        ' 完成后状态切换到SERVO_READY
    ENDIF
END SUB

SUB Handle_SYS_HOMING(event)
    IF event = EVENT_STOP
        ' 清空任务缓冲区，停止当前任务
        ' 完成后状态切换到SERVO_READY
    ELSEIF event = EVENT_HOME_DONE
        ' 完成后状态切换到READY
    ELSE
        ' 输出正在运动
        ' 完成后状态切换到HOMING
    ENDIF

END SUB


SUB Handle_SYS_READY(event)
    IF event = EVENT_HOME THEN
        ' 执行回零操作
        ' 完成后状态切换到HOMING
    ELSEIF event = EVENT_JOINT THEN
        ' 下发单轴运动
        ' 完成后状态切换到RUNNING
    ELSEIF event = EVENT_CART_JOG THEN
        ' 下发点动
        ' 完成后状态切换到RUNNING
    ELSEIF event = EVENT_TRAJ THEN
        ' 下发轨迹
        ' 完成后状态切换到RUNNING
    ELSE
        ' 输出等待运动指令
        ' 完成后状态切换到READY
    ENDIF
END SUB


SUB Handle_SYS_RUNNING(event)
    IF event = EVENT_STOP
        ' 清空任务缓冲区，停止当前任务
        ' 完成后状态切换到SERVO_READY
    ELSEIF event = EVENT_JOINT_DONE
        ' 完成后状态切换到SERVO_READY
    ELSEIF event = EVENT_CART_JOG_DONE
        ' 完成后状态切换到SERVO_READY
    ELSEIF event = EVENT_TRAJ_DONE
        ' 完成后状态切换到SERVO_READY
    ELSE
        ' 输出正在运动
        ' 完成后状态切换到RUNNING
    ENDIF

END SUB


SUB Handle_SYS_ERROR(event)
    IF event = EVENT_ERROR_RESET
        ' 完成后状态切换到SERVO_READY
    ELSE
        ' 输出存在错误
        ' 完成后状态切换到ERROR
    ENDIF

END SUB