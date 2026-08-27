#include "zmcbuildin.h" 
#include "myeigen.h"

/*#include "stdarg.h"
#include "stdio.h"
#include "string.h"
#include "stdlib.h"
#include "stddef.h"*/


// 轴号映射需要更改

#define NULL 0

#ifdef  __cplusplus
extern "C" {
#endif


uint8 g_printflag = 0;
struct_userframeinfo g_soframeinfo[SOFRAME_FRAME_NUM] = {0};

// 参数初始化，每次调用正逆解都要执行一次
// 数据是从TABLE中来的
uint32 SOFRAME_INIT1000(struct_soZmcDisp *pzmc,  struct_soFrameStatus* pframe, TYPE_TABLE* pParaList)
{
    rtprintf("SOFRAME_INIT1000\n");
    int16 i, j; 
    struct_userframeinfo  *pf =NULL;

    g_soframeinfo[0].u_j1 = *pParaList;
	g_soframeinfo[0].u_j2 = *(pParaList + 1);
	g_soframeinfo[0].u_j3 = *(pParaList + 2);
	g_soframeinfo[0].u_j4 = *(pParaList + 3);
    g_soframeinfo[0].u_j5 = *(pParaList + 4);

    for(i = 0; i < 5; i++)
    {
        for(j = 0; j < 3; j++)
        {
            g_soframeinfo[0].b[i][j] = *(pParaList + 5 + i*3 + j);
        }
    }

    for(i = 0; i < 5; i++)
    {
        for(j = 0; j < 3; j++)
        {
            g_soframeinfo[0].m[i][j] = *(pParaList + 20 + i*3 + j);
        }
    }

    for(i = 0; i < 5; i++)
    {
        g_soframeinfo[0].limb0[i] = *(pParaList + 35 + i);
    }

    g_soframeinfo[0].LENGTH_UNIT = *(pParaList + 40);

    for(i = 0; i < SOFRAME_TABLE_NUM; i++)
	{
		g_soframeinfo[0].m_table[i] = pParaList[i];
	}

    


    // 存储 每次init都需要
    pframe->m_pPrivate = (void *)&g_soframeinfo[0];

    //更新当前机械手姿态
    pframe->m_iHand = 0;//意思就是有多个解的时候选哪个
    
    pf = (struct_userframeinfo *)pframe->m_pPrivate; 
    if(NULL == pf)
    {
        return -1;
    }

    // 打印输出
    // rtprintf("init %.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d\n",pf->m_flen1,pf->m_flen2,pf->m_flen3,pf->m_flen4,pf->m_pulse1,pf->m_pulse2,pf->m_pulse3,pf->m_pulse4,pf->m_pulsev,pframe->m_iHand);

    return 0;
}



// 逆解
// pfWorldin	输入世界坐标units单位
// ihand	    输入坐标对应姿态, -1表示使用当前姿态.
uint32 SOFRAME_RETRANS1000(struct_soZmcDisp *pzmc,  struct_soFrameStatus* pframe, TYPE_FRAME *pfWorldin, int32 ihand, TYPE_FRAME* pfJointPulseout)
{
    
	int i;  
    double uw[6];
	struct_userframeinfo  *pf = NULL;

	
    pf = (struct_userframeinfo *)pframe->m_pPrivate;
    
    if(NULL == pf)
	{
        return -1;
    }

    // 2 axis test 交换位置输出
    // uw[1] = pfWorldin[0];   // 位置 x   mm
    // uw[0] = pfWorldin[1];   // 位置 y   mm
    // pfJointPulseout[0] = uw[0] * g_soframeinfo->u_j1;
    // pfJointPulseout[1] = uw[1] * g_soframeinfo->u_j2;
    
    
    // 旋转支链最短690mm(+350mm)
    // 其他支链最短686.22mm(+350mm)
    // ==============================================================================
    
    //把世界坐标脉冲转为um和角度  pfWorldin 已经是除以units的值了
    uw[0] = pfWorldin[0];   // 位置 x   um
    uw[1] = pfWorldin[1];   // 位置 y   um
    uw[2] = pfWorldin[2];   // 位置 z   um
    uw[3] = pfWorldin[3];   // 位置 phi 角度  动平台z轴和世界坐标z轴的夹角
    uw[4] = pfWorldin[4];   // 位置 theta 角度  动平台z轴在世界坐标xoy平面投影线和世界坐标x轴夹角

    //转弧度
    uw[3] = radians(uw[3]);
    uw[4] = radians(uw[4]);

    
    //逆解过程
    // double B1Ob[3];
    // double R_plant[3][3]
    vec3 B[5];
    vec3 M[5];
    vec3 Mw[5];
    vec3 ObB1;
    vec3 xb, yb, zb;
    vec3 v_temp;
    mat3x3 R_plant;  // [xb yb zb]

    vec3 v_plant;  // OaOb
    vec3 v_limb[5];  // 支链向量
    vec3 s_limb[5];  // 支链向量归一化
    float l_limb[5];  // 支链长度
    fp32 l_limb0[5];  // 直连初始长度

    for(int i_axis = 0; i_axis < 5; i_axis++)
    {
        B[i_axis].x = g_soframeinfo->b[i_axis][0];
        B[i_axis].y = g_soframeinfo->b[i_axis][1];
        B[i_axis].z = g_soframeinfo->b[i_axis][2];

        // in plant coordiant
        M[i_axis].x = g_soframeinfo->m[i_axis][0];
        M[i_axis].y = g_soframeinfo->m[i_axis][1];
        M[i_axis].z = g_soframeinfo->m[i_axis][2];
        
        l_limb0[i_axis] = g_soframeinfo->limb0[i_axis];        
    }
    
    v_plant.x = uw[0];
    v_plant.y = uw[1];
    v_plant.z = uw[2];

    // ObB1 = -v_plant + B1
    vec3_mult_v_copy(&v_temp, &v_plant, -1);
    vec3_add_copy(&ObB1, &(B[0]), &v_temp);

    // zb
    zb.x = sin(uw[4])*cos(uw[3]);
    zb.y = sin(uw[4])*sin(uw[3]);
    zb.z = cos(uw[4]);

    // xb = (ObB1 x zb) / ||ObB1 x zb|| 
    vec3_cross_copy(&xb, &ObB1, &zb);
    vec3_normalize_copy(&xb, &xb);

    // yb = zb x xb
    vec3_cross_copy(&yb, &zb, &xb);

    // R_plant = [xb yb zb]
    col_vec_to_mat3x3_copy(&R_plant, &xb, &yb, &zb);

    // movable plant vector in world coordiant
    for(int i_axis = 0; i_axis < 5; i_axis++)
    {
        mat3x3_mult_v3_copy(&(Mw[i_axis]), &R_plant, &(M[i_axis]));
    }

    // 计算支链长度
    for(int i_axis = 0; i_axis < 5; i_axis++)
    {
        // v_limb(i) = - B(i) + v_plant + Mw(i)
        vec3_mult_v_copy(&v_temp, &(B[i_axis]), -1);
        vec3_add_copy(&(v_limb[i_axis]), &v_plant, &(Mw[i_axis]));
        vec3_add_copy(&(v_limb[i_axis]), &v_temp, &(v_limb[i_axis]));
        l_limb[i_axis] = vec3_length(&(v_limb[i_axis]));
    }

    // 转化为脉冲数
    pfJointPulseout[0] = (l_limb[0] - l_limb0[0]) * g_soframeinfo->u_j1;
    pfJointPulseout[1] = (l_limb[1] - l_limb0[1]) * g_soframeinfo->u_j2;
    pfJointPulseout[2] = (l_limb[2] - l_limb0[2]) * g_soframeinfo->u_j3;
    pfJointPulseout[3] = (l_limb[3] - l_limb0[3]) * g_soframeinfo->u_j4;
    pfJointPulseout[4] = (l_limb[4] - l_limb0[4]) * g_soframeinfo->u_j5;
    // 检查代码时用
    // pfJointPulseout[0] = 0 * g_soframeinfo->u_j1;
    // pfJointPulseout[1] = 0 * g_soframeinfo->u_j2;
    // pfJointPulseout[2] = 0 * g_soframeinfo->u_j3;
    // pfJointPulseout[3] = 0 * g_soframeinfo->u_j4;
    // pfJointPulseout[4] = 0 * g_soframeinfo->u_j5;


    //打印输出测试
    if(1 == g_printflag)
    {
        rtprintf("SOFRAME_RETRANS1000 逆解\n");
		rtprintf("retrans input %.6f,%.6f,%.6f,%.6f,%.6f\n",uw[0],uw[1],uw[2],uw[3],uw[4]);
		rtprintf("retrans output %.6f,%.6f,%.6f,%.6f,%.6f\n",pfJointPulseout[0], pfJointPulseout[1], pfJointPulseout[2], pfJointPulseout[3], pfJointPulseout[4]);
        rtprintf("limb length %.10f,%.10f,%.10f,%.10f,%.10f\n",l_limb[0], l_limb[1], l_limb[2], l_limb[3], l_limb[4]);
        g_printflag = 0; 
    }
    
    return 0;
}

uint32 SOFRAME_TRANS1000(struct_soZmcDisp *pzmc,  struct_soFrameStatus* pframe, TYPE_FRAME*pfJointPulsein, int32 *pHand, TYPE_FRAME* pfWorldout)
{
	int i;  
    double uj[6];
	
    // 正解过程，输入关节坐标，输出关节坐标
    // 但是这里回过零了，所以直接取0
    struct_userframeinfo  *pf =NULL;
	pf = (struct_userframeinfo *)pframe->m_pPrivate;

    fp32 LENGTH_UNIT = g_soframeinfo[0].LENGTH_UNIT;
    
    if(NULL == pf)
    {
        return -1;
    }

	// uj[0] = *(pfJointPulsein + 0) / pf->u_j1;
    // uj[1] = *(pfJointPulsein + 1) / pf->u_j2;
    
    // 必须先回零=================================================================
    pfWorldout[0] = 0;  // x
    pfWorldout[1] = 0;  // y
    pfWorldout[2] = -800 * LENGTH_UNIT;  // z
    pfWorldout[3] = 0;  // theta
    pfWorldout[4] = 0;  // phi

    // pfWorldout[0] = 0;  // x
    // pfWorldout[1] = 0;  // y
    // pfWorldout[2] = 0;  // z
    // pfWorldout[3] = 0;  // theta
    // pfWorldout[4] = 0;  // phi
    // =================================================================

    
    //打印输出测试 
    if(0 == g_printflag)
    {
        rtprintf("SOFRAME_TRANS1000 正解\n");
        rtprintf("trans input %.6f,%.6f,%.6f,%.6f,%.6f\n output ,%.6f,%.6f,%.6f,%.6f,%.6f\n",uj[0],uj[1],uj[2],uj[3],uj[4],pfWorldout[0],pfWorldout[1],pfWorldout[2],pfWorldout[3],pfWorldout[4]);
        g_printflag = 1;
    }
    
    return 0;
}



#ifdef  __cplusplus
	}
#endif
