#ifndef PTECLIENT_H
#define PTECLIENT_H

#include "netCommon.h"
#include "linklist.h"
#include "agreement.h"
#include <pthread.h>

#ifdef __cplusplus
extern "C" {
#endif


#define PC_BUFF_MAXLEN         2048

#define PTE_FREE(P) if(0!=P){free(P); P=0;}

typedef enum PC_CMD_STATE{
    PC_CMD_INIT               = 0x00,
    PC_CMD_CONNECTING,
    PC_CMD_CONNECTED,
    PC_CMD_LOGINING,
    PC_CMD_LOGINED,

    PC_CMD_SEND_HEARTBEAT,
    PC_CMD_RECIVE_HEARTBEAT,

    PC_CMD_FAILED,
    PC_CMD_ERROR,
}PC_CMD_STATE;


/*客户端命令结构体*/
typedef struct pteCmdClient_t{
    unsigned char    state;                  /*状态*/
    int              timeout;                /*超时时间*/

    int              longinStep;             /*登录步骤*/

    USER_INFO        userInfo;               /*用户信息*/
    int              ip;                     /*ip*/
    int              port;                   /*port*/
    unsigned char    serialNum[8];           /*序列号*/
    UInt32    id;                     /*用户 id*/

    int              sockFd;                 /*socket*/
    int              refCount;               /*引用数*/
}pteCmdClient_t;

/*客户端结构体*/
typedef struct pteClient_t{
    int              sockFd;                 /*socket*/
    int              run;	
    int              musercount;	
    pteCmdClient_t  *pCmdClient;
    void *aryVideo;
}pteClient_t;

/*初始化使用环境*/
int PC_InitCtx();
/*去初始化,释放资源*/
void PC_UnInitCtx();

/*兴建一个客户端*/
pteClient_t* PC_CreateNew();
/*销毁一个客户端*/
void PC_Delete(pteClient_t* pClient);

/*登录*/
int PC_Login(pteClient_t* pClient, int ip, int port, USER_INFO *userInfo);
/*获取码流*/
int PC_GetStream(pteClient_t* pClient, int channel, int streamType);
void PC_CloseStream(pteClient_t* pClient);


/*select 等待*/
int SK_SelectWaitReadable(unsigned int fd, int msec);
int SK_SelectWaitWriteable(unsigned int fd, int msec);

typedef void *(*sthread)(void*);
int CreatThread(sthread func,void* param);
    
    
#ifdef __cplusplus
}
#endif
#endif
