#include "zmcbuildin.h" 
#include "myeigen.h"

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

    // g_soframeinfo[0].b1[0] = *(pParaList + 5);
    // g_soframeinfo[0].b1[1] = *(pParaList + 6);
    // g_soframeinfo[0].b1[2] = *(pParaList + 7);
    // g_soframeinfo[0].b2[0] = *(pParaList + 8);
    // g_soframeinfo[0].b2[1] = *(pParaList + 9);
    // g_soframeinfo[0].b2[2] = *(pParaList + 10);
    // g_soframeinfo[0].b3[0] = *(pParaList + 11);
    // g_soframeinfo[0].b3[1] = *(pParaList + 12);
    // g_soframeinfo[0].b3[2] = *(pParaList + 13);
    // g_soframeinfo[0].b4[0] = *(pParaList + 14);
    // g_soframeinfo[0].b4[1] = *(pParaList + 15);
    // g_soframeinfo[0].b4[2] = *(pParaList + 16);
    // g_soframeinfo[0].b5[0] = *(pParaList + 17);
    // g_soframeinfo[0].b5[1] = *(pParaList + 18);
    // g_soframeinfo[0].b5[2] = *(pParaList + 19);

    // g_soframeinfo[0].m1[0] = *(pParaList + 20);
    // g_soframeinfo[0].m1[1] = *(pParaList + 21);
    // g_soframeinfo[0].m1[2] = *(pParaList + 22);
    // g_soframeinfo[0].m2[0] = *(pParaList + 23);
    // g_soframeinfo[0].m2[1] = *(pParaList + 24);
    // g_soframeinfo[0].m2[2] = *(pParaList + 25);
    // g_soframeinfo[0].m3[0] = *(pParaList + 26);
    // g_soframeinfo[0].m3[1] = *(pParaList + 27);
    // g_soframeinfo[0].m3[2] = *(pParaList + 28);
    // g_soframeinfo[0].m4[0] = *(pParaList + 29);
    // g_soframeinfo[0].m4[1] = *(pParaList + 30);
    // g_soframeinfo[0].m4[2] = *(pParaList + 31);
    // g_soframeinfo[0].m5[0] = *(pParaList + 32);
    // g_soframeinfo[0].m5[1] = *(pParaList + 33);
    // g_soframeinfo[0].m5[2] = *(pParaList + 34);


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
    uw[1] = pfWorldin[0];   // 位置 x   mm
    uw[0] = pfWorldin[1];   // 位置 y   mm
    pfJointPulseout[0] = uw[0] * g_soframeinfo->u_j1;
    pfJointPulseout[1] = uw[1] * g_soframeinfo->u_j2;
    /*pfJointPulseout[0] = uw[0] * g_soframeinfo->u_j1;
    pfJointPulseout[1] = uw[1] * g_soframeinfo->u_j2;*/
    
    
        
    // ==============================================================================
    /*
    //把世界坐标脉冲转为mm和角度  pfWorldin 已经是除以units的值了
    uw[0] = pfWorldin[0];   // 位置 x   mm
    uw[1] = pfWorldin[1];   // 位置 y   mm
    uw[2] = pfWorldin[2];   // 位置 z   mm
    uw[3] = pfWorldin[3];   // 位置 phi 弧度 
    uw[4] = pfWorldin[4];   // 位置 theta 弧度
    // uw[5] = pfWorldin[5];

    //转弧度
    uw[3] = radians(uw[3]);
    uw[4] = radians(uw[4]);
    // uw[5] = uw[5] / 180 *PI;
    
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

    for(int i_axis = 0; i_axis < 5; i_axis++)
    {
        B[i_axis].x = g_soframeinfo->b[i_axis][0];
        B[i_axis].y = g_soframeinfo->b[i_axis][1];
        B[i_axis].z = g_soframeinfo->b[i_axis][2];

        // in plant coordiant
        M[i_axis].x = g_soframeinfo->m[i_axis][0];
        M[i_axis].y = g_soframeinfo->m[i_axis][1];
        M[i_axis].z = g_soframeinfo->m[i_axis][2];
        
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

    // for(i = 0; i < 3; i++)
    // {
    //     // B1Ob[i] = uw[i] - g_soframeinfo->b[0][i];
    // }

    // 动平台z轴
    // R_plant[0][2] = sin(uw[4])*cos(uw[3]);
    // R_plant[1][2] = sin(uw[4])*sin(uw[3]);
    // R_plant[2][2] = cos(uw[4]);

    // R_plant.m[2][0] = sin(uw[4])*cos(uw[3]);
    // R_plant.m[2][1] = sin(uw[4])*sin(uw[3]);
    // R_plant.m[2][2] = cos(uw[4]);

    // 转化为脉冲数
    pfJointPulseout[0] = l_limb[0] * g_soframeinfo->u_j1;
    pfJointPulseout[1] = l_limb[1] * g_soframeinfo->u_j2;
    pfJointPulseout[2] = l_limb[2] * g_soframeinfo->u_j3;
    pfJointPulseout[3] = l_limb[3] * g_soframeinfo->u_j4;
    pfJointPulseout[4] = l_limb[4] * g_soframeinfo->u_j5;
    */
    // ==============================================================================
     
    //打印输出测试
    if(1 == g_printflag)
    {
        rtprintf("SOFRAME_RETRANS1000 逆解\n");
		rtprintf("retrans input %.6f,%.6f, output ,%.6f,%.6f\n",uw[0],uw[1],pfJointPulseout[0],pfJointPulseout[1],pfJointPulseout[2]);
		g_printflag = 0; 
    }
    
    return 0;
}

uint32 SOFRAME_TRANS1000(struct_soZmcDisp *pzmc,  struct_soFrameStatus* pframe, TYPE_FRAME*pfJointPulsein, int32 *pHand, TYPE_FRAME* pfWorldout)
{
    rtprintf("SOFRAME_TRANS1000 正解\n");
	int i;  
    double uj[6];
	
    // 正解过程，输入关节坐标，输出关节坐标
    // 但是这里回过零了，所以直接取0
    struct_userframeinfo  *pf =NULL;
	pf = (struct_userframeinfo *)pframe->m_pPrivate;
    
    if(NULL == pf)
    {
        return -1;
    }

	uj[0] = *(pfJointPulsein + 0) / pf->u_j1 ;
    uj[1] = *(pfJointPulsein + 1) / pf->u_j2 ;
    
    pfWorldout[0] = 0;
    pfWorldout[1] = 0;

    
    //打印输出测试 
    if(0 == g_printflag)
    {
        rtprintf("SOFRAME_TRANS1000 正解\n");
        rtprintf("trans input %.6f,%.6f, output ,%.6f,%.6f\n",uj[0],uj[1],pfWorldout[0],pfWorldout[1],pfWorldout[2]);
        g_printflag = 1;
    }
    
    return 0;
}



#ifdef  __cplusplus
	}
#endif
