#include "private_protocol.h"
#include "LongseDes.h"
#import <UIKit/UIKit.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#import "XCNotification.h"
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/select.h>
#include <sys/time.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include<unistd.h>

#if 1
#define PRIVATE_LOG(fmt, args...) do { printf("[%s] %s line %d " fmt "\n", __FILE__, __FUNCTION__, __LINE__, ##args ); fflush(stderr);   } while ( 0 )
#else
#define PRIVATE_LOG(fmt, args...)
#endif

typedef void*(*sthread)(void*);
GET_NEXT_FRAME_DATA frameFun;
NSMutableArray *arrayVideo;
int CreatThread(sthread func,void* param)
{
	int iRet=0;
        pthread_t		 threadID;
    	pthread_attr_t   attr;	
	pthread_attr_init(&attr);	
	pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
	iRet=pthread_create(&threadID,&attr,func,param);
	if(iRet != 0)
	{
		(void)pthread_attr_destroy(&attr);
		return -1;
	}
	return 0;
}

int Sendmsg(int msocket,void *data,int datalen)
{
	int sendlen=0;
	sendlen = (int)send(msocket,data,datalen,0);
	if(sendlen >0)
	{
		//printf("SendHeartBeatMsg success!\n");
		return 0;
	}
	else  if ( sendlen< 0 && ( errno == EINTR || errno == EAGAIN ) )
	{
		printf("senddata erro\n");
		return 0;    
	}
	else
	{
		printf("SendHeartBeatMsg failed!!!\n");
		return -1;
	}
	return 0;
}

private_protocol_info_t *private_protocol_init()
{
    private_protocol_info_t *pStreamInfo = 0;

    do{
        pStreamInfo = (private_protocol_info_t*)malloc(sizeof(private_protocol_info_t));
        memset(pStreamInfo,0,sizeof(private_protocol_info_t));
        pStreamInfo->cmdSocketFd = -1;
	pStreamInfo->streamSocketFd = -1;	
        return pStreamInfo;
    }while(0);

    if(0!=pStreamInfo){
        PP_FREE(pStreamInfo);
    }
    return NULL;
}


/*void private_protocol_closeStream(private_protocol_info_t *pStreamInfo)
{
    if(0==pStreamInfo) return;
    pStreamInfo->run = 0;	
    PP_CLOSE_FD(pStreamInfo->cmdSocketFd);	
    PP_CLOSE_FD(pStreamInfo->streamSocketFd);
    PP_FREE(pStreamInfo);

}*/

void* private_protocol_free(void *arg)
{
	printf("private_protocol_free come\n");
	private_protocol_info_t **StreamInfo ;
	int count=0;
	StreamInfo = (private_protocol_info_t **)arg;
	while(1)
	{
		if((*StreamInfo)->usercount ==0)
		{
			PP_FREE(*StreamInfo);
			printf("break\n");
			break;
		}
		else
		{
			if(count<5)
			{
				count++;
            //    sleep(1);
				continue;
			}
			else
			{
				PP_FREE(*StreamInfo);
				break;
			}
		}
	}
	printf("private_protocol_free exit\n");
    return "";
}

void* private_protocol_stop(private_protocol_info_t **pStreamInfo)
{
    
	printf("private_protocol_stop!!\n");
	int iRet=0;
	if(NULL==(*pStreamInfo)) return NULL;
	(*pStreamInfo)->run = 0;
    private_protocol_logout(*pStreamInfo);
	PP_CLOSE_FD((*pStreamInfo)->cmdSocketFd);
	PP_CLOSE_FD((*pStreamInfo)->streamSocketFd);
    
    while(1)
    {
        if((*pStreamInfo)->usercount ==0)
        {
            PP_FREE(*pStreamInfo);
            printf("break\n");
            break;
        }
//        else
//        {
//            DLog(@"这里释放");
//            if(count<5)
//            {
//                count++;
//                continue;
//            }
//            else
//            {
//                PP_FREE(*pStreamInfo);
//                break;
//            }
//        }
        DLog(@"(*pStreamInfo)usercount :%d",(*pStreamInfo)->usercount);
        [NSThread sleepForTimeInterval:0.25f];
    }
    
	if(iRet != 0)
	{
		printf("CreatThread failed!\n");
		return NULL;
	}	
    return NULL;

}

void* private_protocol_heartbeat(private_protocol_info_t *arg )
{
	if(arg == NULL)
	{
		return NULL;
	}
	int iRet=0;
	iRet = CreatThread(private_protocol_sendHeartbeat,(void *)(arg));
	if(iRet != 0)
	{
		printf("CreatThread failed!\n");
		return NULL;
	}
  	iRet = CreatThread(private_protocol_recvHeartbeat,(void *)(arg));
	if(iRet != 0)
	{
		printf("CreatThread failed!\n");
		return NULL;
	}
    return NULL;
}

void setUserData(void* user)
{
    arrayVideo = (__bridge NSMutableArray*)user;
}

void RecvOneFramedata(char *data,int datalen)
{
    unsigned char* pBuf = (unsigned char*)malloc(1024);
    int nTemp = 1024;
    int nCurSize = 0,nRead = 0;
    //每次读取4096个字节
    while (nCurSize!=datalen)
    {
        nRead = ((datalen - nCurSize) > nTemp) ? nTemp : (datalen - nCurSize);
        memcpy(pBuf, data+nCurSize, nRead);
        nCurSize +=nRead;
        NSData *dataInfo = [[NSData alloc] initWithBytes:pBuf length:nRead];
        @synchronized(arrayVideo)
        {
            [arrayVideo addObject:dataInfo];
        }
        dataInfo = nil;
    }
    
    free(pBuf);
}

int  Recvmsg(int msocket,char *buff,int datalen)
{
    int haverecvdatalen = 0;
    int totaldatalen = datalen;
    
    while(totaldatalen>0)
    {
        int recvlen = (int)recv(msocket,buff+haverecvdatalen,totaldatalen,0); //接收真正的请求数据
        if(recvlen> 0)
        {
            totaldatalen -= recvlen;
            haverecvdatalen += recvlen;
            
        }
        else  if ( recvlen< 0 && ( errno == EINTR || errno == EAGAIN ) )
        {
            continue;
        }
        else
        {
            DLog(@"RelayServiceImpl::ProcessMessage( recv  error");
            return -1;
        }	
    }
    return 0;
}


void* recvStream( void *arg)
{
    if(arg==NULL)
    {
    	return NULL;
    }
    char *buff = NULL;
    private_protocol_info_t *streaminfo = NULL;
    streaminfo =	(private_protocol_info_t*)arg;
    ARG_STREAM Stream;
    DLog(@"ARG_STREAM:%li",sizeof(ARG_STREAM));
    char recvstate=0;	
    int rsl;
    int recvLen;
    int buffLen = 0;
    int fd=0;
    fd = streaminfo->streamSocketFd;
   

    buff = malloc(MAX_FRAMESIZE);
    memset(buff,0x00,MAX_FRAMESIZE);	

    streaminfo->usercount++;		
    while(streaminfo->run)
    {
        rsl = SK_SelectWait(fd,3000);
        if(0!=rsl) continue;
        int nRef = 0;
        nRef = (int)recv(fd, (char*)(&Stream), ARG_HEAD_LEN, 0);//head data  head data
        if(nRef < 0 )
        {
            printf("Recvmsg head failed\n");
            recvstate = -1;
            break;
        }
        buffLen = 0;
        if(Stream.bSize>MAX_FRAMESIZE)
        {
            printf("Stream.bSize is %d\n",Stream.bSize);
            PP_FREE(buff);
            buff = malloc(Stream.bSize);
            memset(buff,0x00,Stream.bSize);
        }
        recvLen = Recvmsg(fd,buff,Stream.bSize);
        if (recvLen<0)
        {
            DLog(@"exit");
            break;
        }
        RecvOneFramedata(buff,Stream.bSize);
    }
    PP_FREE(buff);		
    if(recvstate <0)
    {
    	PP_CLOSE_FD(streaminfo->streamSocketFd);
    }
    streaminfo->usercount--; 	
    printf("stop recvStream!!\n");
    return NULL;
}

int  StartGetStream(private_protocol_info_t *arg)
{
	if(arg == NULL)
	{
		return -1;
	}
	int iRet=0;
	iRet = CreatThread(recvStream,(void *)(arg));
	if(iRet != 0)
	{
		printf("CreatThread failed!\n");
		return -1;
	}
    return 0;
}

void* private_protocol_sendHeartbeat(void *arg)
{
    private_protocol_info_t * pInfo=NULL;
    pInfo =(private_protocol_info_t *)arg; 	
    char buff[ARG_BUFF_LEN];
    ARG_CMD *pCmd = (ARG_CMD*)buff;

    struct timeval timeout;
   // int i=0;
    int count=0;
    int nInfo ;
    pCmd->ulFlag = ARG_CMD_HEAD;
    pCmd->ulVersion = ARG_SDK_VERSION_1_1;
    pCmd->usCmd = CMD_ACT_HEADRTBEAT;
    pInfo->usercount++;
    while (pInfo->run)
    {
        timeout.tv_sec = 1;
        timeout.tv_usec = 0;
        if(1==pInfo->isWaitHeartbeatReply)
        {
            if(count>2)
            {
                DLog(@"private_protocol_stop");
        //        private_protocol_stop(&pInfo);
        //        break;
            }
            else
            {
                count++;
            }
        }
        else
        {
            count=0;
            if(pInfo->cmdSocketFd > 0)
            {
                pCmd->ulID = (unsigned int)pInfo->userId;
                int result = Sendmsg(pInfo->cmdSocketFd,(void*)pCmd,ARG_HEAD_LEN);
                if(result<0)
                {
                     printf("Sendmsg failed!\n"); 
                     private_protocol_stop(&pInfo);
                     break;
                }
                pInfo->isWaitHeartbeatReply = 1;

            }
        }
        nInfo = 0 ;
        while (nInfo++<8)
        {
            if (!pInfo->run)
            {
                break;
            }
            select(0, 0, 0, 0, &timeout);
        }
    }
    if(pInfo)
    {
        (pInfo->usercount)--;
    }
    printf("stop sendHeartbeat\n");
    return NULL;
}

void* private_protocol_recvHeartbeat(void *arg)
{
    private_protocol_info_t * pInfo=NULL;
    pInfo =(private_protocol_info_t *)arg; 	
    char buff[ARG_BUFF_LEN];
    ARG_CMD *pCmd = (ARG_CMD*)buff;
    int recvLen=0;

    pCmd->ulFlag = ARG_CMD_HEAD;
    pCmd->ulVersion = ARG_SDK_VERSION_1_1;
    pCmd->usCmd = CMD_ACT_HEADRTBEAT;

    pInfo->usercount++; 	
    while (pInfo->run)
    {
        int result = SK_SelectWait(pInfo->cmdSocketFd,4000);
        if(result !=0)
        {
            continue;
        }
        if(1 == pInfo->isWaitReply)
        {
            printf("waiting cmd, skip...\n");
            usleep(10*1000);
            continue;
        }
        recvLen = (int)recv(pInfo->cmdSocketFd,(void*)pCmd,ARG_HEAD_LEN,0);
        if(ARG_HEAD_LEN != recvLen) continue;
        if(pCmd->ulBufferSize>0)
        {
            recv(pInfo->cmdSocketFd,(void*)(buff+ARG_HEAD_LEN),pCmd->ulBufferSize,0);
        }
        DLog(@"出问题了???");
        pInfo->isWaitHeartbeatReply = 0;

    }
    pInfo->usercount--;	
    printf("stop recvHeartbeat\n");
    return NULL;
}

int private_protocol_sendCmd(private_protocol_info_t* pStreamInfo, int cmdType, char *inData, int inLen, char *outData, int *outLen)
{
   
    char buff[ARG_BUFF_LEN] = {0};
    ARG_CMD *cmd = (ARG_CMD *)buff;

    int socketFd;
    int rsl;

    
  
    if(0== pStreamInfo) return -1;
    if(pStreamInfo->isWaitReply) return -1;
	
    socketFd = (CMD_GET_STREAM==cmdType) ? pStreamInfo->streamSocketFd : pStreamInfo->cmdSocketFd;
    if(0>socketFd) return -1;

    cmd->ulFlag = ARG_CMD_HEAD;
    cmd->ulVersion = ARG_SDK_VERSION_1_1;
    cmd->usCmd = cmdType;
    cmd->ulID = (unsigned int)pStreamInfo->userId;
    cmd->ulBufferSize = inLen;
    if(cmd->ulBufferSize > 0){
        memcpy(buff+ARG_HEAD_LEN,(void*)inData,cmd->ulBufferSize);
    }
    do{
         pStreamInfo->isWaitReply = 1;
         rsl = (int)send(socketFd,(void*)buff,(ARG_HEAD_LEN+cmd->ulBufferSize),0);
        if(rsl != (int)(ARG_HEAD_LEN+cmd->ulBufferSize)){
            PRIVATE_LOG("send data failed! rsl = %d",rsl);
            break;
        }
        while(pStreamInfo->run)
        {
            rsl = SK_SelectWait(socketFd,3000);
            if(0!=rsl)
            {
                 goto RETURN_FAULT;
            };
            rsl = (int)recv(socketFd,(void*)cmd,ARG_HEAD_LEN,0);
            if(ARG_HEAD_LEN != rsl)
            if(0!=rsl) 
            {
                 goto RETURN_FAULT;
            };
            if(cmd->ulBufferSize>0)
            {
                    rsl = (int)recv(socketFd,(void*)(buff+ARG_HEAD_LEN),cmd->ulBufferSize,0);
            }
            if(cmd->ulBufferSize>0)
            {
                if(rsl>0)
                {
                    if(outData!=0)
                    {
                        memcpy((void*)outData,(void*)(buff+ARG_HEAD_LEN),cmd->ulBufferSize);
                    }
                    if(outLen!=0)
                    {
                        *outLen = (int)cmd->ulBufferSize;
                    }
                }
            }
            if(CMD_ACT_LOGIN==cmd->usCmd && CMD_SUCCESS==cmd->ucState)
            {
                pStreamInfo->userId = cmd->ulID;
                break;
            }
            else if(CMD_ACT_HEADRTBEAT==cmd->usCmd)
            {
                printf("recv CMD_ACT_HEADRTBEAT\n");
                pStreamInfo->isWaitHeartbeatReply = 0;
                continue;     //»Áπ˚Ω” ’µΩµƒ «–ƒÃ¯œÏ”¶£¨‘ÚºÃ–¯Ω” ’	
            }
            else
            {
                //printf("recv other command\n");
                break;
            }
        }
        pStreamInfo->isWaitReply = 0;
        return cmd->ucState;
    }while(0);
    
    pStreamInfo->isWaitReply = 0;  	
    return -1;
    
    RETURN_FAULT:
     	pStreamInfo->isWaitReply = 0;  	
    	return -1;		
		
}

int private_protocol_login(private_protocol_info_t *pStreamInfo, unsigned int ip, unsigned int port, char *name, char *passwd)
{
    USER_INFO userInfo;
    char serialNum[ARG_SERIALNUM_LEN]={0};
    char passwdBuff[16]={0};
    int rsl;

    memset(&userInfo,0,sizeof(USER_INFO));
    if(0==pStreamInfo) return -1;
    pStreamInfo->ip = ip;
    pStreamInfo->port = port;
  	
    do{
        pStreamInfo->cmdSocketFd = SK_ConnectTo(ip,port);
        if(0>pStreamInfo->cmdSocketFd) break;

        rsl = private_protocol_sendCmd(pStreamInfo,CMD_GET_SERIALNUM,0,0,serialNum,0);
        if(0!=rsl) break;

        sprintf((char*)userInfo.ucUsername,"%s",name);
        sprintf(passwdBuff,"%s",passwd);
        PP_DES_Encode((char*)userInfo.ucPassWord,passwdBuff,serialNum,16);
        PP_DES_Encode((char*)userInfo.ucSerialNum,serialNum,serialNum,ARG_SERIALNUM_LEN);
        
        rsl = private_protocol_sendCmd(pStreamInfo,CMD_ACT_LOGIN,(char*)&userInfo,sizeof(USER_INFO),0,0);
        
        if(0<rsl) break;

        printf("login success uid is %lu\n",pStreamInfo->userId);

	pStreamInfo->run = 1;
	private_protocol_heartbeat(pStreamInfo);
		
        return 0;
    }while(0);
    PP_CLOSE_FD(pStreamInfo->cmdSocketFd);
    PP_CLOSE_FD(pStreamInfo->streamSocketFd);	
      
    pStreamInfo->ip = 0;
    pStreamInfo->port = 0;
    pStreamInfo->userId = 0;

    return -1;
}

int private_protocol_getStream(private_protocol_info_t *pStreamInfo, int channelNo, int streamNo)
{
    STREAM_INFO streamInfo;
    int rsl;

    if(0==pStreamInfo){ return -1; }

    memset(&streamInfo,0,sizeof(STREAM_INFO));
    streamInfo.ucCH = channelNo;
    streamInfo.ucStreamType = streamNo;

    do{
        pStreamInfo->streamSocketFd = SK_ConnectTo(pStreamInfo->ip,pStreamInfo->port);
        if(0>pStreamInfo->streamSocketFd) break;

        rsl = private_protocol_sendCmd(pStreamInfo,CMD_GET_STREAM,(char*)&streamInfo,sizeof(STREAM_INFO),0,0);
        if(0!=rsl) break;

        rsl = StartGetStream(pStreamInfo);
	 if(0!=rsl) break;	
        DLog("获取码流成功");

        return 0;
    }while(0);
    PP_CLOSE_FD(pStreamInfo->streamSocketFd);
    return -1;
}

void activate_nonblock(int fd)
{
    int ret;
    int flags = fcntl(fd, F_GETFL);
    if (flags == -1)
        DLog(@"fcntl error");
    
    flags |= O_NONBLOCK;
    ret = fcntl(fd, F_SETFL, flags);
    if (ret == -1)
        DLog(@"fcntl error");
}

void deactivate_nonblock(int fd)
{
    int ret;
    int flags = fcntl(fd, F_GETFL);
    if (flags == -1)
        DLog(@"fcntl error");
    
    flags &= ~O_NONBLOCK;
    ret = fcntl(fd, F_SETFL, flags);
    if (ret == -1)
        DLog(@"fcntl error");
}

int SK_ConnectTo(unsigned int ip,int port)
{
    struct sockaddr_in address;

    int sockfd;
    int rsl;

    sockfd = socket(AF_INET,SOCK_STREAM,0);
    if(-1==sockfd) return -1;

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = ip;
    address.sin_port = htons(port);
    int wait_seconds = 5;
    if (wait_seconds > 0)
        activate_nonblock(sockfd);
    
    int set = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));//不捕获  SIGPIPE
    
    int ret=0;
    rsl = connect(sockfd,(const struct sockaddr *)&address,sizeof(struct sockaddr_in));
    if(rsl < 0 && errno == EINPROGRESS)
    {
        DLog(@"errno:%d",errno);
        fd_set connect_fdset;
        struct timeval timeout;
        FD_ZERO(&connect_fdset);
        FD_SET(sockfd, &connect_fdset);
        
        timeout.tv_sec = wait_seconds;
        timeout.tv_usec = 0;
        
        do
        {
            /* 一旦连接建立，套接字就可写 */
            ret = select(sockfd + 1, NULL, &connect_fdset, NULL, &timeout);
        }
        while (ret < 0 && errno == EINTR);
        
        if (ret == 0)
        {
            errno = ETIMEDOUT;
            return -1;
        }
        else if (ret < 0)
            return -1;
        
        else if (ret == 1)
        {
            int err;
            socklen_t socklen = sizeof(err);
            int sockoptret = getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &err, &socklen);
            if (sockoptret == -1)
            {
                return -1;
            }
            if (err == 0)
            {
                ret = 0;//建立成功
            }
            else
            {
                errno = err;
                ret = -1;
            }
        }
    }
//    if (wait_seconds > 0)
//    {
//        deactivate_nonblock(sockfd);
//    }
    return sockfd;
}

int SK_SelectWait(unsigned int fd, int msec)
{
    struct timeval timeout;
    fd_set fds;
    int rsl;

    timeout.tv_sec = msec/1000;
    timeout.tv_usec = (msec%1000)*1000;
    
    FD_ZERO(&fds);
    FD_SET(fd,&fds);

    rsl = select(fd+1,&fds,0,0,&timeout);
    if(0<rsl && 0!=FD_ISSET(fd,&fds)){
        return 0;
    }
    return -1;
}

int private_protocol_logout(private_protocol_info_t *pStreamInfo)
{
    USER_INFO userInfo;
    int rsl;
    memset(&userInfo,0,sizeof(USER_INFO));
    if(0==pStreamInfo) return -1;
    do{
        rsl = private_protocol_sendCmd(pStreamInfo,CMD_ACT_LOGOUT,(char*)&userInfo,sizeof(USER_INFO),0,0);
        if(0!=rsl) break;
        printf("login out success\n");
        return 0;
    }while(0);
    
    printf("login failed!\n");
    PP_CLOSE_FD(pStreamInfo->cmdSocketFd);
    PP_CLOSE_FD(pStreamInfo->streamSocketFd);
    
    return -1;
}

