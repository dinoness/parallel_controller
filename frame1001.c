#include "zmcbuildin.h" 

/*#include "stdarg.h"
#include "stdio.h"
#include "string.h"
#include "stdlib.h"
#include "stddef.h"*/


#define NULL 0

#ifdef  __cplusplus
extern "C" {
#endif


uint8 g_printflag = 0;
struct_userframeinfo g_soframeinfo[SOFRAME_FRAME_NUM] = {0};


// 数据是从TABLE中来的
uint32 SOFRAME_INIT1001(struct_soZmcDisp *pzmc,  struct_soFrameStatus* pframe, TYPE_TABLE* pParaList)
{
    int16 i; 
    struct_userframeinfo  *pf =NULL;

    g_soframeinfo[0].m_flen1 = *pParaList;
	g_soframeinfo[0].m_flen2 = *(pParaList + 1);
	g_soframeinfo[0].m_flen3 = *(pParaList + 2);
	g_soframeinfo[0].m_flen4 = *(pParaList + 3);
    g_soframeinfo[0].m_flen5 = *(pParaList + 4);

}










#ifdef  __cplusplus
	}
#endif
