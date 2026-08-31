GLOBAL SUB CTRL_MOVE()
    PRINT "Close loop control move start."
    INI_CYCLE(1, TASK_CTRL_MOVE, PID_MOVE)
END SUB

GLOBAL SUB CTRL_MOVE_END()
    PRINT "Close loop control move end."
    INI_CYCLE(2, TASK_CTRL_MOVE, PID_MOVE)
END SUB

SUB PID_MOVE()
    ' 读取指令，做闭环微调，再发送指令
END SUB
