#include "devdiscovery.h"
#include <stdio.h>
#import "RtspInfo.h"
#import <Foundation/Foundation.h>
#include <string.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#import "XCNotification.h"
#include <netdb.h>
#include <netinet/in.h>

#include <net/if.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <time.h>

#define DD_DEBUG_FLAG 1        /*¥Úø™ ‰≥ˆ*/
/********************************************************************************************/
/*******************************           ∫Í         ***************************************/
/********************************************************************************************/
#if DD_DEBUG_FLAG
#define DD_DEBUG(fmt,args...) printf("DEBUG %s-%d: "fmt"\n",__FUNCTION__,__LINE__,## args);
#else
#define DD_DEBUG(fmt,args...)
#endif

#define DD_CLOSE_SOCKET(fd)   do{if(0>fd) break; close(fd); fd = -1; }while(0)
#define DD_FREE(ptr) do{if(0==(ptr))break; free(ptr); ptr=0; }while(0)
/********************************************************************************************/
/*******************************        »´æ÷±‰¡ø       ***************************************/
/********************************************************************************************/
static pthread_t   DD_g_StartDiscoveryThrID=0;
static int         DD_g_pPipes[2] = {-1,-1};
static task_t     *DD_g_pTask[DD_TASK_MAXNUM];
int                DD_g_taskNum = 0;

static DSC_NETWORK_INFO  DD_g_NetworkInfo;
/********************************************************************************************/
/*******************************       æ≤Ã¨∫Ø ˝…˘√˜     ***************************************/
/********************************************************************************************/
/*–¬Ω®»ŒŒÒ*/
static task_t* DD_CreateTask(DD_TASKTYPE_TYPE type, DD_TASK_PROC procFun, void *pData, unsigned int dataLen);
/*œ˙ªŸ»ŒŒÒ*/
static void    DD_DeleteTask(task_t* pTask);
/*ÃÌº”»ŒŒÒ*/
static int     DD_AddNewTask(task_t* pTask);
/*“∆≥˝»ŒŒÒ*/
static int     DD_RemoveTask(task_t* pTask);
/*÷¥––»ŒŒÒ*/
static int     DD_ProcTask(task_t* pTask);


/*π‹¿Ì…Ë±∏À—À˜∫Ø ˝*/
static int DD_ProcSearchDev(struct task_t *pTask);
/*π‹¿Ì∑˛ŒÒ∆˜∫Ø ˝*/
static int DD_ProcServer(struct task_t *pTask);
/*π‹¿Ì–ﬁ∏ƒ±æµÿÕ¯¬Á∫Ø ˝*/
static int DD_ProcModifyLocalNetConfig(struct task_t *pTask);
/*π‹¿Ì–ﬁ∏ƒ‘∂∂ÀÕ¯¬Á∫Ø ˝*/
static int DD_ProcModifyDevNetConfig(struct task_t *pTask);

/*Ã·π©∑˛ŒÒ∫Ø ˝*/
static int DD_HannelServerEvent(struct task_t *pTask);
/*Ã·π©–ﬁ∏ƒ∑˛ŒÒ*/
static int DD_HannelServerModify(DSC_MODIFY_INFO *pModify, DSC_MODIFY_RESPONSE_INFO *pModifyResponse);


static void DD_PrintBit(unsigned char *pData, int len);

/********************************************************************************************/
/*******************************       ∫Ø ˝ µœ÷        ***************************************/
/********************************************************************************************/
/*÷˜œﬂ≥Ã*/
int DD_StartDiscoveryThread()
{
	struct timeval timeout;
	fd_set fds;
    int maxFd;

    task_t  *pTask;
    int      curTime = 0;
    int      len;
    int      ret;
    int      i;

    DD_DEBUG("Start DevDescovery...\n");

    while(1)
    {
        timeout.tv_sec = 5;
        timeout.tv_usec = 0;
        /*ÃÌº”π‹µ¿ fd*/
        FD_ZERO(&fds);
        maxFd = DD_g_pPipes[0];
        FD_SET(DD_g_pPipes[0],&fds);
        /*ÃÌº” task fd*/
        for(i=0;i<DD_TASK_MAXNUM;i++){
            pTask = *(DD_g_pTask + i);
            if(0==pTask) continue;
            if(DD_TASKSTATE_FAILED == pTask->state){
                DD_RemoveTask(pTask);
                DD_DeleteTask(pTask);
            }
            FD_SET(pTask->sockFd,&fds);
            maxFd = (pTask->sockFd > maxFd) ? pTask->sockFd : maxFd;
        }
        /*ø™ º select*/
        ret = select(maxFd+1,&fds,0,0,&timeout);
//        DD_DEBUG("select result + %d--%d--%d",ret,maxFd,DD_g_taskNum);
        if(ret < 0)
        {
            DD_DEBUG("Socket error. rebulid...--error:%d",errno);
            sleep(1);
            continue;
        }
        else if(0==ret)
        {
            /*ºÏ≤È≤¢πÿ±’≥¨ ±µƒÀ—À˜socket*/
            curTime = time(0);
            for(i=0;i<DD_TASK_MAXNUM;i++){
                pTask = *(DD_g_pTask + i);
                if(0==pTask) continue;
                if(curTime - pTask->time > 10){
                    pTask->state = DD_TASKSTATE_TIMEOUT;
                    DD_ProcTask(pTask);
                    if(DD_TASKSTATE_WAIT != pTask->state){
                        DD_RemoveTask(pTask);
                        DD_DeleteTask(pTask);
                    }
                }
            }
            continue;
        }
        /*≥ı ºªØ»´æ÷Õ¯¬Á≤Œ ˝*/
        if(0!=DD_InitNetworkInfo(&DD_g_NetworkInfo)){
            sleep(1);
            continue;
        }
        /*ÃÌº”–¬µƒÀ—À˜socket*/
       // if(1 == FD_ISSET(DD_g_pPipes[0],&fds)){
		    int  ret = FD_ISSET(DD_g_pPipes[0],&fds);
			//printf("ret is %d\n");
			if(ret>0){
            len = read(DD_g_pPipes[0],&pTask,sizeof(task_t*));
            if(sizeof(task_t*)==len){
                if(DD_TASK_MAXNUM <= DD_g_taskNum){
                    pTask->state = DD_TASKSTATE_FAILED;
                }
                DD_ProcTask(pTask);
                if(DD_TASKSTATE_WAIT != pTask->state){
                    DD_DeleteTask(pTask);
                }else{
                    DD_AddNewTask(pTask);
                }
            }
        }
        for(i=0;i<DD_TASK_MAXNUM;i++){
            pTask = *(DD_g_pTask + i);
            if(0==pTask) continue;
            //if(1==FD_ISSET(pTask->sockFd,&fds)){
			if(0<FD_ISSET(pTask->sockFd,&fds)){
                DD_ProcTask(pTask);
                if(DD_TASKSTATE_WAIT!=pTask->state){
                    DD_RemoveTask(pTask);
                    DD_DeleteTask(pTask);
                }
            }
        }
    }
    DD_g_StartDiscoveryThrID = 0;
	return -1;
}

/*socket */
static int DD_CreateUDPSokcet(int port)
{
	int sockFd;
	int ret;
	int flags;
	const int opt = 1;
	struct sockaddr_in ipAddr; 
	do{
		//–ÀΩ® socket
		sockFd = socket(AF_INET, SOCK_DGRAM, 0);
		if(-1==sockFd){
			DD_DEBUG("Create socket failed!");
			break;
		}
		//…Ë÷√∏√Ã◊Ω”◊÷Œ™π„≤•¿‡–Õ£¨
		ret = setsockopt(sockFd, SOL_SOCKET, SO_BROADCAST, (char *)&opt, sizeof(opt));
		if(-1 == ret){
			DD_DEBUG("Set socket SO_BROADCAST failed!");
			break;
		}
		// ∞Û∂®µÿ÷∑
		memset(&ipAddr,0,sizeof(struct sockaddr_in));
		ipAddr.sin_family = AF_INET;
		ipAddr.sin_addr.s_addr = htonl(INADDR_ANY);
		ipAddr.sin_port = htons(port);
		ret = bind(sockFd,(struct sockaddr *)&(ipAddr), sizeof(struct sockaddr_in));
        DD_DEBUG("port:%d",port);
		if(-1 == ret)
		{
			DD_DEBUG("Bind rsockfd failed!");
			break;
		}
		//socket ∑«◊Ë»˚
		flags = fcntl(sockFd,F_GETFL,0);
		ret = fcntl(sockFd,F_SETFL,flags|O_NONBLOCK);
		if(-1 == ret)
		{
			DD_DEBUG("Set socket unblock failed!");
			break;
		}
		return sockFd;
	}while(0);

    DD_CLOSE_SOCKET(sockFd);
	return -1;
}

/*Õ‚≤øµ˜”√Ω”ø⁄*/
int discovery(void)   
{
    if(0!=DD_g_StartDiscoveryThrID) return 0;

    int ret;

    do{
        ret = pipe(DD_g_pPipes);
        if(0!=ret) break;
        ret= pthread_create(&DD_g_StartDiscoveryThrID,0,(void*(*)(void*))DD_StartDiscoveryThread,0);
        if(0!=ret) break;

        ret = DD_StartServer();
        if(0!=ret) break;
        return 0;
    }while(0);
    DD_CLOSE_SOCKET(DD_g_pPipes[0]);
    DD_CLOSE_SOCKET(DD_g_pPipes[1]);
    DD_g_StartDiscoveryThrID = 0;
    return -1;
}


int DD_StartServer()
{
    task_t *pTask;
    int len;

    do{
        /*–¬Ω®»ŒŒÒ*/
        pTask = DD_CreateTask(DD_TASKTYPE_SERVER,DD_ProcServer,0,0);
        if(0==pTask) break;
        /*–¥»Î»ŒŒÒ*/
        len = write(DD_g_pPipes[1],&pTask,sizeof(task_t*));
        if(sizeof(task_t*)!=len){
            break;
        }
        return 0;
    }while(0);
    DD_DeleteTask(pTask);
    return -1;
}

int DD_SearchDev()
{
	task_t *pTask;
    int     len;

    if(0==DD_g_StartDiscoveryThrID) return -1;

    DSC_SEARCH_INFO              searchInfo;

    do{
        /*–¬Ω®»ŒŒÒ*/
        pTask = DD_CreateTask(DD_TASKTYPE_SEARCH,DD_ProcSearchDev,&searchInfo,sizeof(DSC_SEARCH_INFO));
        if(0==pTask) break;
        /*–¥»Î»ŒŒÒ*/
        len = write(DD_g_pPipes[1],&pTask,sizeof(task_t*));
        if(sizeof(task_t*)!=len)
        {
            break;
        }
        return 0;
    }while(0);
    
    DD_DeleteTask(pTask);
    return -1;
}

/*∏ƒ±‰‘∂≥Ã…Ë±∏Õ¯¬Á≤Œ ˝*/
int DD_ModifyDevNetConfig(DSC_MODIFY_INFO *pModify)
{
    task_t *pTask = 0;
    int len;

    if(0==pModify) return -1;

    do{
        /*–¬Ω®»ŒŒÒ*/
        pTask = DD_CreateTask(DD_TASKTYPE_MODIFY,DD_ProcModifyDevNetConfig,pModify,sizeof(DSC_MODIFY_INFO));
        if(0==pTask) break;
        /*–¥»Î»ŒŒÒ*/
        len = write(DD_g_pPipes[1],&pTask,sizeof(task_t*));
        if(sizeof(task_t*)!=len){
            break;
        }
        return 0;
    }while(0);
    DD_DeleteTask(pTask);
    return -1;
}

/********************************************************************************************/
/*******************************       æ≤Ã¨∫Ø ˝ µœ÷     ***************************************/
/********************************************************************************************/
static task_t* DD_CreateTask(DD_TASKTYPE_TYPE type, DD_TASK_PROC procFun, void *pData, unsigned int dataLen)
{
    task_t* pTask;

    do{
        pTask = (task_t*)malloc(sizeof(task_t));
        if(0==pTask) break;
        memset(pTask,0,sizeof(task_t));

        pTask->sockFd = -1;
        pTask->type = type;
        pTask->state = DD_TASKSTATE_UNDO;
        pTask->procFun = procFun;
        pTask->dataLen = dataLen;
        pTask->time = time(0);

        if(0!=pTask->dataLen){
            pTask->pData = malloc(pTask->dataLen);
            memcpy(pTask->pData,pData,pTask->dataLen);
        }else{
            pTask->pData = pData;
        }

        return pTask;
    }while(0);
    return 0;
}

static void DD_DeleteTask(task_t* pTask)
{
    if(0==pTask) return;

    if(0!=pTask->dataLen){
        DD_FREE(pTask->pData);
    }
    DD_CLOSE_SOCKET(pTask->sockFd);
    DD_FREE(pTask);
}

static int DD_AddNewTask(task_t* pTask)
{
    int i;
    if(0==pTask) return -1;
    if(DD_TASK_MAXNUM <= DD_g_taskNum) return -1;

    for(i=0;i<DD_TASK_MAXNUM;i++){
        if(0==DD_g_pTask[i]){
            DD_g_pTask[i] = pTask;
            DD_g_taskNum ++;
            break;
        }
    }
    DD_DEBUG("add new task success!");
    return ((i>=DD_TASK_MAXNUM)?(-1):0);
}

static int DD_RemoveTask(task_t *pTask)
{
    int i;
    if(0==pTask) return -1;
    if(0>=DD_g_taskNum) return -1;

    for(i=0;i<DD_TASK_MAXNUM;i++){
        if(pTask == DD_g_pTask[i]){
            DD_g_pTask[i] = 0;
            DD_g_taskNum --;
            break;
        }
    }
    return ((i>=DD_TASK_MAXNUM)?(-1):0);
}

static int DD_ProcTask(task_t *pTask)
{
    if(0==pTask) return -1;
    if(0!=pTask->procFun){
        return (*pTask->procFun)(pTask);
    }
    return -1;
}

static int DD_ProcSearchDev(struct task_t *pTask)
{
	DSC_SEARCH_INFO             *pSearch;
    DSC_SEARCH_RESPONSE_INFO    *pSearchResponse;
    unsigned char                pPasswork[DSC_PASSWORD_MAXLEN];

    char  inBuff[DSC_MESSAGE_MAXLEN];
    int   inLen;

    struct sockaddr_in           ipAddr;
    int   sockaddrLen;
    int   len;

    if(0==pTask) return -1;

    do{
        if(DD_TASKSTATE_UNDO == pTask->state){
            /*ipAddr*/
            memset(&ipAddr,0,sizeof(struct sockaddr_in));
            ipAddr.sin_family = AF_INET;
            ipAddr.sin_addr.s_addr = inet_addr("255.255.255.255");
            ipAddr.sin_port = htons(DSC_BROADCAST_PORT);
            /*content*/
            pSearch = (DSC_SEARCH_INFO*)pTask->pData;
		
            if(0==pSearch) break;
            memset(pSearch,0,sizeof(DSC_SEARCH_INFO));
            snprintf((char*)pSearch->ucCheckCode,DSC_CHECKCODE_LEN,DSC_CHECKCODE);
            pSearch->ucMesType = DSC_MT_SEARCH;
            snprintf((char*)pSearch->srcInfo.ucIpAddr,DSC_IPV4ADDR_LEN,"%s",(char*)DD_g_NetworkInfo.ucIpAddr);
            snprintf((char*)pSearch->srcInfo.ucMacAddr,DSC_MACADDR_LEN,"%s",(char*)DD_g_NetworkInfo.ucMacAddr);
            /*create udp sock*/
            pTask->sockFd = DD_CreateUDPSokcet(0);
			
            if(0>pTask->sockFd) break;
            /*send*/
            sockaddrLen = sizeof(struct sockaddr_in);
            len = sendto(pTask->sockFd,pSearch,sizeof(DSC_SEARCH_INFO),0,(struct sockaddr*)&ipAddr,sockaddrLen);
		
            if(sizeof(DSC_SEARCH_INFO)!=len){ break; }
            pTask->state = DD_TASKSTATE_WAIT;
        }else if(DD_TASKSTATE_WAIT == pTask->state){
            pSearchResponse = (DSC_SEARCH_RESPONSE_INFO*)inBuff;
            NSMutableArray *aryDevice = [NSMutableArray array];
            while(1)
            {
                sockaddrLen = sizeof(struct sockaddr_in);
                inLen = recvfrom(pTask->sockFd, inBuff, DSC_MESSAGE_MAXLEN, 0, (struct sockaddr*)&ipAddr,(socklen_t*)&sockaddrLen);
                if(inLen< (int)sizeof(DSC_SEARCH_RESPONSE_INFO)){ break; }
                if(DSC_MT_SEARCH_RESP == inBuff[DSC_MESTYPE_OFFSET])
                {
                    PP_DES_Decode((char*)pPasswork,(char*)pSearchResponse->userInfo.ucPassword,DSC_ENCODE_KEY,DSC_PASSWORD_MAXLEN);
                    memcpy((char*)pSearchResponse->userInfo.ucPassword,(char*)pPasswork,DSC_PASSWORD_MAXLEN);
                    DD_FoundNewDev(pSearchResponse);
                    RtspInfo *rtspModel = [[RtspInfo alloc] init];
                    if (pSearchResponse->playformInfo.ucChNum==0)
                    {
                        rtspModel.strType = @"IPC";
                        rtspModel.nPort = ntohl(pSearchResponse->devInfo.ulRtspPort);
                    }
                    else
                    {
                        if (strncmp((const char *)pSearchResponse->playformInfo.ucDevType,"DVR",3)==0)
                        {
                            rtspModel.strType = @"DVR";
                            rtspModel.nPort = ntohl(pSearchResponse->devInfo.ulPrivatePort);
                        }
                        else
                        {
                            rtspModel.strType = @"NVR";
                            rtspModel.nPort = ntohl(pSearchResponse->devInfo.ulRtspPort);
                        }
                    }
                    rtspModel.nChannel = pSearchResponse->playformInfo.ucChNum;
                    rtspModel.strDevName = [NSString stringWithFormat:@"%s",pSearchResponse->devInfo.ucDevName];
                    rtspModel.strAddress = [NSString stringWithFormat:@"%s",pSearchResponse->networkInfo.ucIpAddr];
                    rtspModel.strUser = [NSString stringWithFormat:@"%s",pSearchResponse->userInfo.ucUsername];
                    rtspModel.strPwd = [NSString stringWithFormat:@"%s",pSearchResponse->userInfo.ucPassword];
                    [aryDevice addObject:rtspModel];
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:NS_SEARCH_DEVICE_FOR_WLAN_VC object:aryDevice];
        }
        return 0;
    }while(0);
    pTask->state = DD_TASKSTATE_FAILED;
    return -1;
}


static int DD_ProcServer(struct task_t *pTask)
{
    int   ret;
    if(0==pTask) return -1;

    do{
        if(DD_TASKSTATE_UNDO == pTask->state){
            pTask->sockFd = DD_CreateUDPSokcet(DSC_BROADCAST_PORT);
            if(0>pTask->sockFd) break;
            pTask->state = DD_TASKSTATE_WAIT;
        }else if(DD_TASKSTATE_WAIT == pTask->state){
            while(1){
                ret = DD_HannelServerEvent(pTask);
                if(0!=ret) break;
            }
        }else if(DD_TASKSTATE_TIMEOUT == pTask->state){
            pTask->state = DD_TASKSTATE_WAIT;
            pTask->time = time(0);
        }
        return 0;
    }while(0);
    pTask->state = DD_TASKSTATE_FAILED;
    return -1;
}

static int DD_ProcModifyLocalNetConfig(struct task_t *pTask)
{
    DSC_MODIFY_INFO *pModify;
    if(0==pTask) return -1;

    pModify = pTask->pData;
    do{
        if(DD_TASKSTATE_UNDO == pTask->state){
            DD_ModifyLocalNetConfig(pModify);
            pTask->state = DD_TASKSTATE_COMPLETE;
        }
        return 0;
    }while(0);
    return -1;
}

static int DD_ProcModifyDevNetConfig(struct task_t *pTask)
{
    DSC_MODIFY_INFO            *pModify;
    DSC_MODIFY_RESPONSE_INFO   *pModifyResp;
    unsigned char               pPassword[DSC_PASSWORD_MAXLEN];
    unsigned char               pInBuff[DSC_MESSAGE_MAXLEN];
    int                         inLen;

    struct sockaddr_in          ipAddr;
    int                         sockaddrLen;
    int                         len;


    if(0==pTask) return -1;

    DD_DEBUG("DD_ProcModifyDevNetConfig task state = %d",pTask->state);

    do{
        if(DD_TASKSTATE_UNDO==pTask->state){
            pModify = (DSC_MODIFY_INFO*)pTask->pData;
            /*≥ı ºªØ–ﬁ∏ƒ∞¸*/
            snprintf((char*)pModify->ucCheckCode,DSC_CHECKCODE_LEN,DSC_CHECKCODE);
            pModify->ucMesType = DSC_MT_MODIFY;
            PP_DES_Encode((char*)pPassword,(char*)pModify->securityInfo.ucPassword,DSC_ENCODE_KEY,DSC_PASSWORD_MAXLEN);
            memcpy((char*)pModify->securityInfo.ucPassword,(char*)pPassword,DSC_PASSWORD_MAXLEN);
            snprintf((char*)pModify->srcInfo.ucIpAddr,DSC_IPV4ADDR_LEN,"%s",(char*)DD_g_NetworkInfo.ucIpAddr);
            snprintf((char*)pModify->srcInfo.ucMacAddr,DSC_MACADDR_LEN,"%s",(char*)DD_g_NetworkInfo.ucMacAddr);
            /*≥ı ºªØ∑¢ÀÕµÿ÷∑*/
            ipAddr.sin_family = AF_INET;
            ipAddr.sin_addr.s_addr = inet_addr("255.255.255.255");
            ipAddr.sin_port = htons(DSC_BROADCAST_PORT);
            /*–ÀΩ® socket*/
            pTask->sockFd = DD_CreateUDPSokcet(0);
            if(0>pTask->sockFd) break;
            /*∑¢ÀÕ–ﬁ∏ƒ∞¸*/
            sockaddrLen = sizeof(struct sockaddr_in);
            len = sendto(pTask->sockFd,pModify,sizeof(DSC_MODIFY_INFO),0,(struct sockaddr*)&ipAddr,sockaddrLen);
            if(sizeof(DSC_MODIFY_INFO)!=len)break;
            pTask->state = DD_TASKSTATE_WAIT;
        }else if(DD_TASKSTATE_WAIT==pTask->state){
            pModify = (DSC_MODIFY_INFO*)pTask->pData;
            pModifyResp = (DSC_MODIFY_RESPONSE_INFO*)pInBuff;

            inLen = recvfrom(pTask->sockFd, pInBuff, DSC_MESSAGE_MAXLEN, 0, (struct sockaddr*)&ipAddr,(socklen_t*)&sockaddrLen);
            if((inLen>= (int)sizeof(DSC_MODIFY_RESPONSE_INFO)) && (DSC_MT_MODIFY_RESP==pInBuff[DSC_MESTYPE_OFFSET]) ) {
                DD_DEBUG("response state -----------------------2");
                if((0==strncmp((char*)pModifyResp->dstInfo.ucIpAddr,(char*)DD_g_NetworkInfo.ucIpAddr,DSC_IPV4ADDR_LEN)) &&
                    (0==strncmp((char*)pModifyResp->dstInfo.ucMacAddr,(char*)DD_g_NetworkInfo.ucMacAddr,DSC_MACADDR_LEN))){
                    DD_DEBUG("response state -----------------------1");
                    DD_ModifyDevNetConfigResponse(DD_TASKSTATE_COMPLETE,pModifyResp);
                    pTask->state = DD_TASKSTATE_COMPLETE;
                }
            }
        }else if(DD_TASKSTATE_TIMEOUT==pTask->state){
            DD_ModifyDevNetConfigResponse(DD_TASKSTATE_TIMEOUT,0);
        }
        return 0;
    }while(0);
    pTask->state = DD_TASKSTATE_FAILED;
    return -1;
}

static int DD_HannelServerEvent(struct task_t *pTask)
{
    DSC_SEARCH_INFO           *pSearch;
    DSC_SEARCH_RESPONSE_INFO  *pSearchResp;
    DSC_MODIFY_INFO           *pModify;
    DSC_MODIFY_RESPONSE_INFO  *pModifyResp;

    unsigned char              pPassword[DSC_PASSWORD_MAXLEN];
    struct sockaddr_in         ipAddr;
    int                        sockaddrLen;

    char                       pInBuff[DSC_MESSAGE_MAXLEN];
    int                        inLen;
    char                       pOutBuff[DSC_MESSAGE_MAXLEN];
    int                        outLen;
    int                        ret;

    do{
        sockaddrLen = sizeof(struct sockaddr_in);
        inLen = recvfrom(pTask->sockFd, pInBuff, DSC_MESSAGE_MAXLEN, 0, (struct sockaddr*)&ipAddr,(socklen_t*)&sockaddrLen);
        if(inLen< (int)(DSC_CHECKCODE_LEN + sizeof(unsigned char))) break;
        /*∑˛ŒÒÀ—À˜∞¸*/
        if(DSC_MT_SEARCH == pInBuff[DSC_MESTYPE_OFFSET]){
            pSearch = (DSC_SEARCH_INFO*)pInBuff;
            pSearchResp = (DSC_SEARCH_RESPONSE_INFO*)pOutBuff;
            /*∂™∆˙±æª˙∑¢≥ˆµƒÀ—À˜∞¸*/
            if( (0!=strncmp((char*)pSearch->srcInfo.ucIpAddr,(char*)DD_g_NetworkInfo.ucIpAddr,DSC_IPV4ADDR_LEN)) &&
                (0!=strncmp((char*)pSearch->srcInfo.ucMacAddr,(char*)DD_g_NetworkInfo.ucMacAddr,DSC_MACADDR_LEN))){
                /*≥ı ºªØ∑µªÿ∞¸*/
                memset(pSearchResp,0,sizeof(DSC_SEARCH_RESPONSE_INFO));
                snprintf((char*)pSearchResp->ucCheckCode,DSC_CHECKCODE_LEN,"%s",DSC_CHECKCODE);
                pSearchResp->ucMesType = DSC_MT_SEARCH_RESP;
                /*Õ¯¬Á*/
                memcpy((char*)&pSearchResp->networkInfo,&DD_g_NetworkInfo,sizeof(DSC_NETWORK_INFO));
                /*…Ë±∏*/
                DD_InitDevInfo(&pSearchResp->devInfo);
                /*∆ΩÃ®*/
                DD_InitPlatformInof(&pSearchResp->playformInfo);
                /*”√ªß*/
                ret = DD_InitUserInfo(&pSearchResp->userInfo);
                if(0!=ret) break;



                PP_DES_Encode((char*)pPassword,(char*)pSearchResp->userInfo.ucPassword,DSC_ENCODE_KEY,DSC_PASSWORD_MAXLEN);
                memcpy((char*)pSearchResp->userInfo.ucPassword,(char*)pPassword,DSC_PASSWORD_MAXLEN);



                /*∑µªÿÀ—À˜∞¸*/
                sockaddrLen = sizeof(struct sockaddr_in);
                ipAddr.sin_addr.s_addr = inet_addr("255.255.255.255");
                outLen = sendto(pTask->sockFd,pOutBuff,sizeof(DSC_SEARCH_RESPONSE_INFO),0,(struct sockaddr*)&ipAddr,sockaddrLen);
                if(sizeof(DSC_SEARCH_RESPONSE_INFO) != outLen) break;
            }
        /*∑˛ŒÒ–ﬁ∏ƒ∞¸*/
        }else if(DSC_MT_MODIFY == pInBuff[DSC_MESTYPE_OFFSET]){
            pModify = (DSC_MODIFY_INFO*)pInBuff;
            pModifyResp =  (DSC_MODIFY_RESPONSE_INFO*)pOutBuff;
            ret = DD_HannelServerModify(pModify,pModifyResp);
            if(0==ret){
                /*∑µªÿ–ﬁ∏ƒ∞¸*/
                sockaddrLen = sizeof(struct sockaddr_in);
                ipAddr.sin_addr.s_addr = inet_addr("255.255.255.255");
                outLen = sendto(pTask->sockFd,pOutBuff,sizeof(DSC_MODIFY_RESPONSE_INFO),0,(struct sockaddr*)&ipAddr,sockaddrLen);
                if(sizeof(DSC_MODIFY_RESPONSE_INFO) != outLen) break;
            }
        }
        return 0;
    }while(0);
    return -1;
}


static int DD_HannelServerModify(DSC_MODIFY_INFO *pModify, DSC_MODIFY_RESPONSE_INFO *pModifyResp)
{
    DSC_USER_INFO       userInfo;
    unsigned char       pPassword[DSC_PASSWORD_MAXLEN];
    int                 ret;
    int                 len;

    if(0==pModify) return -1;
    if(0==pModifyResp) return -1;

    DD_DEBUG("dst ip is %s",pModify->dstInfo.ucIpAddr);
    DD_DEBUG("local ip is %s",DD_g_NetworkInfo.ucIpAddr);
    DD_DEBUG("dst mac is %s",pModify->networkInfo.ucMacAddr);
    DD_DEBUG("local mac is %s",DD_g_NetworkInfo.ucMacAddr);

    do{
        /*π˝¬À–ﬁ∏ƒ∞¸*/
        if( (0!=strncmp((char*)pModify->dstInfo.ucIpAddr,(char*)DD_g_NetworkInfo.ucIpAddr,DSC_IPV4ADDR_LEN)) ||
            (0!=strncmp((char*)pModify->dstInfo.ucMacAddr,(char*)DD_g_NetworkInfo.ucMacAddr,DSC_MACADDR_LEN))) break;

        /*≥ı ºªØ–ﬁ∏ƒ∑µªÿ∞¸*/
        memset(pModifyResp,0,sizeof(DSC_MODIFY_RESPONSE_INFO));
        snprintf((char*)pModifyResp->ucCheckCode,DSC_CHECKCODE_LEN,DSC_CHECKCODE);
        pModifyResp->ucErrorCode = DSC_ERRORCODE_SUCCESS;
        pModifyResp->ucMesType = DSC_MT_MODIFY_RESP;
        memcpy((char*)&pModifyResp->dstInfo,(char*)&pModify->srcInfo,sizeof(DSC_TERMINAL_INFO));

        /*–£—È*/
        DD_InitUserInfo(&userInfo);
        PP_DES_Encode((char*)pPassword,(char*)userInfo.ucPassword,DSC_ENCODE_KEY,DSC_PASSWORD_MAXLEN);
        if((0!=strncmp((char*)pModify->securityInfo.ucUsername,(char*)userInfo.ucUsername,DSC_USERNAME_MAXLEN)) ||
           (0!=strncmp((char*)pModify->securityInfo.ucPassword,(char*)pPassword,DSC_PASSWORD_MAXLEN))){
           pModifyResp->ucErrorCode = DSC_ERRORCODE_USERPASSWD_ERROR;
           DD_DEBUG("user passwd error %s--%s",(char*)pModify->securityInfo.ucUsername,(char*)pPassword);
        }
        ret = DD_CheckNetworkIsValid(&pModify->networkInfo);
        if(0!=ret){
            pModifyResp->ucErrorCode = DSC_ERRORCODE_ARGE_ERROR;
            DD_InitDevInfo(&pModifyResp->devInfo);
        }else{
            memcpy((char*)&pModifyResp->devInfo,(char*)&pModify->devInfo,sizeof(DSC_DEV_INFO));
        }
        ret = DD_CheckDevInfoIsValid(&pModify->devInfo);
        if(0!=ret){
            pModifyResp->ucErrorCode = DSC_ERRORCODE_ARGE_ERROR;
            memcpy((char*)&pModifyResp->networkInfo,(char*)&DD_g_NetworkInfo,sizeof(DSC_DEV_INFO));
        }else{
            memcpy((char*)&pModifyResp->networkInfo,(char*)&pModify->networkInfo,sizeof(DSC_DEV_INFO));
        }

        if(DSC_ERRORCODE_SUCCESS == pModifyResp->ucErrorCode){
            task_t *pTask = 0;
            /*–ÀΩ®»ŒŒÒ*/
            pTask = DD_CreateTask(DD_TASKTYPE_DOMODIFY,DD_ProcModifyLocalNetConfig,pModify,sizeof(DSC_MODIFY_INFO));
            if(0==pTask) break;
            /*–¥»Î»ŒŒÒ*/
            len = write(DD_g_pPipes[1],&pTask,sizeof(task_t*));
            if(sizeof(task_t*)!=len){
                break;
            }
        }
        return 0;
    }while(0);
    return -1;
}

/*******************************************************************************************************************
************************************  ≤ªÕ¨∆ΩÃ®÷ª–Ë“™–ﬁ∏ƒ¥À∑÷∏Óœﬂ“‘œ¬¥˙¬Î. ***********************************************
********************************************************************************************************************/
/*∑¢œ÷–¬…Ë±∏*/
int DD_FoundNewDev(DSC_SEARCH_RESPONSE_INFO *pResponse)   //√ø¥Œªÿµ˜÷ª∑µªÿ“ª∏ˆ…Ë±∏µƒœ‡πÿ–≈œ¢
{

    DD_DEBUG("ipadd is %s",pResponse->networkInfo.ucIpAddr);
    DD_DEBUG("dev name is %s",pResponse->devInfo.ucDevName);
    DD_DEBUG("rtsp port = %d, private port = %d", ntohl(pResponse->devInfo.ulRtspPort),ntohl(pResponse->devInfo.ulPrivatePort));
    DD_DEBUG("channel num is %d",pResponse->playformInfo.ucChNum);
    DD_DEBUG("dev type is %s",pResponse->playformInfo.ucDevType);
    DD_DEBUG("software version is %s",pResponse->playformInfo.ucSoftwareVersion);
    DD_DEBUG("admin:%s--password:%s", pResponse->userInfo.ucUsername,pResponse->userInfo.ucPassword);
    
    DD_DEBUG("--------------------------------------------------------\n");
    return 0;
}

/*∏ƒ±‰‘∂≥Ã…Ë±∏Õ¯¬Á≤Œ ˝ªÿ∏¥*/
int DD_ModifyDevNetConfigResponse(unsigned char state, DSC_MODIFY_RESPONSE_INFO *pModifyResponse)
{

    DD_DEBUG("---------------------------------------------------------------");
    DD_DEBUG("result code %d",pModifyResponse->ucErrorCode);
    DD_DEBUG("ip is %s",pModifyResponse->networkInfo.ucIpAddr);
    DD_DEBUG("mac is %s",pModifyResponse->networkInfo.ucMacAddr);
    DD_DEBUG("task state is %d-%p-%d",state,pModifyResponse,pModifyResponse->ucErrorCode);




    return 0;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////

/*∏ƒ±‰Õ¯¬Á≤Œ ˝*/
int DD_ModifyLocalNetConfig(DSC_MODIFY_INFO *pInfo)
{
#if 1
    DD_DEBUG("ipadd is %s\n",pInfo->networkInfo.ucIpAddr);
    DD_DEBUG("netmask is %s\n",pInfo->networkInfo.ucNetmaskAddr);
    DD_DEBUG("gateway is %s\n",pInfo->networkInfo.ucGatewayAddr);
    DD_DEBUG("dns is %s\n",pInfo->networkInfo.ucDnsAddr1);
    DD_DEBUG("mac is %s\n",pInfo->networkInfo.ucMacAddr);
    DD_DEBUG("web port is %d\n",pInfo->devInfo.ulHttpPort);
    DD_DEBUG("rtsp port is %d\n",pInfo->devInfo.ulRtspPort);
    DD_DEBUG("useDHCP is %d\n",pInfo->networkInfo.ucDhcpEnable);
#endif

#if 0
    sdk_eth_cfg_t EthInfo;
    sdk_net_mng_cfg_t NetMng;
    sdk_log_item_t g_LogItem;
    int ret;

    do{

        ret = databaseOperate(SDK_MAIN_MSG_NET_LINK_CFG,SDK_PARAM_GET,NULL,0,&EthInfo,sizeof(EthInfo));
        if(ret == -1)
        {
            Printf("Database fail!\n!");
            break;
        }
        ret = databaseOperate(SDK_MAIN_MSG_NET_MNG_CFG,SDK_PARAM_GET,NULL,0,&NetMng,sizeof(NetMng));
        if(ret == -1)
        {
            Printf("Database fail!\n!");
            break;
        }

        strcpy(EthInfo.ip_info.ip_addr,pInfo->networkInfo.ucIpAddr);
        strcpy(EthInfo.ip_info.mask,pInfo->networkInfo.ucNetmaskAddr);
        strcpy(EthInfo.ip_info.gateway,pInfo->networkInfo.ucGatewayAddr);
        strcpy(EthInfo.ip_info.dns1,pInfo->networkInfo.ucDnsAddr1);
        EthInfo.ip_info.enable_dhcp = pInfo->networkInfo.ucDhcpEnable;

        NetMng.dvr_data_port = pInfo->devInfo.ulRtspPort;
        NetMng.http_port  = pInfo->devInfo.ulHttpPort;

        ret = databaseOperate(SDK_MAIN_MSG_NET_LINK_CFG,SDK_PARAM_SET,NULL,0,&EthInfo,sizeof(EthInfo));
        if(ret == -1)
        {
            Printf("Database fail!\n!");
            break;
        }

        ret = databaseOperate(SDK_MAIN_MSG_NET_MNG_CFG,SDK_PARAM_SET,NULL,0,&NetMng,sizeof(NetMng));
        if(ret == -1)
        {
            Printf("Database fail!\n!");
            break;
        }

        // ≤Â»Î»’÷æ---–ﬁ∏ƒÕ¯¬Á–≈œ¢
        g_LogItem.logId = ((LOG_PARAMS_SETUP << 8) | LOG_NETWORK_SETUP);
        strcpy((char *)g_LogItem.user,"by IPCsearch");
        ret= databaseOperate(SDK_MAIN_MSG_LOG,SDK_LOG_INSERT,NULL,0,&g_LogItem,sizeof(sdk_log_item_t));
        if(ret<0)
        {
            Printf("databaseOperate  SDK_MAIN_MSG_LOG write  fail \n");
        }

        return 0;
    }while(0);
    return -1;
#endif
    return 0;
}

int DD_CheckNetworkIsValid(DSC_NETWORK_INFO *pInfo)
{
    DD_DEBUG("DD_CheckNetworkIsValid %p",pInfo);
    return 0;
}

int DD_CheckDevInfoIsValid(DSC_DEV_INFO *pInfo)
{
    DD_DEBUG("DD_CheckDevInfoIsValid %p",pInfo);
    return 0;
}

int DD_InitUserInfo(DSC_USER_INFO *pInfo)
{
    if(0==pInfo) return -1;
    memset(pInfo,0,sizeof(DSC_USER_INFO));

    snprintf((char*)pInfo->ucUsername,DSC_USERNAME_MAXLEN,"admin");
    snprintf((char*)pInfo->ucPassword,DSC_USERNAME_MAXLEN,"admin");
    return 0;
}
#if 0
int DD_InitNetworkInfo(DSC_NETWORK_INFO *pInfo)
{
    sdk_eth_cfg_t EthInfo;
    int ret;

    if(0==pInfo) return -1;
    memset(pInfo,0,sizeof(DSC_NETWORK_INFO));

    ret = databaseOperate(SDK_MAIN_MSG_NET_LINK_CFG,SDK_PARAM_GET,NULL,0,&EthInfo,sizeof(EthInfo));
    if(0<=ret)
    {
        pInfo->ucDhcpEnable = EthInfo.ip_info.enable_dhcp;
    }
    snprintf((char*)pInfo->ucIpAddr,DSC_IPV4ADDR_LEN,(char*)EthInfo.ip_info.ip_addr);
    snprintf((char*)pInfo->ucGatewayAddr,DSC_IPV4ADDR_LEN,(char*)EthInfo.ip_info.gateway);
    snprintf((char*)pInfo->ucNetmaskAddr,DSC_IPV4ADDR_LEN,(char*)EthInfo.ip_info.mask);
    snprintf((char*)pInfo->ucDnsAddr1,DSC_IPV4ADDR_LEN,(char*)EthInfo.ip_info.dns1);
    netGetMac("eth0",pInfo->ucMacAddr);

    pInfo->ulMemberIsValid = DSC_NETWORK_DHCP_VALID | DSC_NETWORK_IP_VALID | DSC_NETWORK_NETMASK_VALID |
            DSC_NETWORK_GATEWAY_VALID | DSC_NETWORK_MAC_VALID;
    return 0;
}
#endif
#if 1
int DD_InitNetworkInfo(DSC_NETWORK_INFO *pInfo)
{
	//printf("jacker DD_InitNetworkInfo!!\n");
	int            inet_sock;
    struct ifreq   ifr;

    if(0==pInfo) return -1;
    memset(pInfo,0,sizeof(DSC_NETWORK_INFO));

    do{
        inet_sock = socket(AF_INET, SOCK_DGRAM, 0);
        strcpy(ifr.ifr_name, "en0");
        if (ioctl(inet_sock, SIOCGIFADDR, &ifr) < 0)
        {
             perror("ioctl");
        }
        close(inet_sock);
        snprintf((char*)pInfo->ucIpAddr,DSC_IPV4ADDR_LEN,"%s", inet_ntoa(((struct sockaddr_in*)&(ifr.ifr_addr))->sin_addr));
//		snprintf((char*)pInfo->ucIpAddr,DSC_IPV4ADDR_LEN,"%s", "172.18.191.41");
        pInfo->ulMemberIsValid |= DSC_NETWORK_IP_VALID;
        snprintf((char*)pInfo->ucMacAddr,DSC_MACADDR_LEN,"%s","a1b2c3d4e5d6");
        pInfo->ulMemberIsValid |= DSC_NETWORK_MAC_VALID;

        return 0;
    }while(0);
    return -1;
}
#endif

int DD_InitDevInfo(DSC_DEV_INFO *pInfo)
{
//    sdk_comm_cfg_t	commInfo;
//    int ret;

//    if(0==pInfo) return -1;
//    memset(pInfo,0,sizeof(DSC_DEV_INFO));

//    pInfo->ulMemberIsValid |= DSC_DEV_NAME_VALID;
//    //snprintf((char*)pInfo->ucDevName,DSC_DEVNAME_MAXLEN,"%s","newdev newdev");

//    ret = GetPort(&pInfo->ulRtspPort ,&pInfo->ulHttpPort, &pInfo->ulPlaybackPort);
//    if(0==ret){
//        pInfo->ulMemberIsValid |= DSC_DEV_RTSPPORT_VALID;
//        pInfo->ulMemberIsValid |= DSC_DEV_HTTPPORT_VALID;
//        pInfo->ulMemberIsValid |= DSC_DEV_PLAYBACKPORT_VALID;
//    }
//    ret=databaseOperate(SDK_MAIN_MSG_COMM_CFG,SDK_PARAM_GET,NULL,0,&commInfo,sizeof(commInfo));
//    if(0>ret)
//    {
//        //fprintf(stderr,"databaseOperate  SDK_MAIN_MSG_COMM_CFG write  fail %s:%d\n",__FILE__,__LINE__);
//        snprintf((char*)pInfo->ucDevName,DSC_DEVNAME_MAXLEN,"HS_NVR");
//    }
//    else
//    {
//        snprintf((char*)pInfo->ucDevName,DSC_DEVNAME_MAXLEN,commInfo.dvr_name);
//    }
//    pInfo->ulMemberIsValid |= DSC_DEV_NAME_VALID;

    return 0;
}

int DD_InitPlatformInof(DSC_PLATFORM_INFO *pInfo)
{
    if(0==pInfo) return -1;
    memset(pInfo,0,sizeof(DSC_PLATFORM_INFO));

    pInfo->ucPlatformType = 500;
    pInfo->ulMemberIsValid = DSC_PLATFORM_DEV_TYPE_VALID | DSC_PLATFORM_TYPE_VALID;
    snprintf((char*)pInfo->ucDevType,DSC_DEVTYPE_MAXLEN,"%s",DSC_DEVTYPE_IPCAM);


    pInfo->ucChNum =90;


//    pInfo->ucChNum = configGetDisplayNum();
//    pInfo->ulMemberIsValid |= DSC_PLATFORM_CHANNEL_VALID;
//#ifdef HI3535
//        snprintf((char*)pInfo->ucSoftwareVersion,DSC_SOFTWARE_VERSION_MAXLEN,"NVR_HI3535_%d_%s",pParam->ucChNum,NVR_VERSION);
//#else
//        snprintf((char*)pInfo->ucSoftwareVersion,DSC_SOFTWARE_VERSION_MAXLEN,"NVR_HI3520D_%d_%s",pInfo->ucChNum,NVR_VERSION);
//#endif

//    pInfo->ulMemberIsValid |= DSC_PLATFORM_CHANNEL_VALID;
//    pInfo->ulMemberIsValid |= DSC_PLATFORM_SOFTWARE_VERSION_VALID;

    return 0;
}

static void DD_PrintBit(unsigned char* pData, int len)
{
    int i;
    int iBuff;
    if(0==pData) return;

    printf("--");
    for(i=0;i<len;i++){


        iBuff = (unsigned int)pData[i];
        printf("%x ",iBuff);
    }
    printf("--\n");
}


