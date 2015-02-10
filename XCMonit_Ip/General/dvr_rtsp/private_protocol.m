#include "private_protocol.h"
#include "LongseDes.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

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
//#define PRIVATE_LOG(fmt, args...) do { fprintf(stderr, "\n========= [%s ] %s line %d " fmt "\n", __FILE__, __FUNCTION__, __LINE__, ##args ); fflush(stderr);   } while ( 0 )
#define PRIVATE_LOG(fmt, args...) do { printf("[%s] %s line %d " fmt "\n", __FILE__, __FUNCTION__, __LINE__, ##args ); fflush(stderr);   } while ( 0 )
#else
#define PRIVATE_LOG(fmt, args...)
#endif

typedef void *(*sthread)(void*);

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
	sendlen = send(msocket,data,datalen,0);
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

void private_protocol_free(void *arg)
{
	printf("private_protocol_free come\n");
	private_protocol_info_t **StreamInfo ;
	int count=0;
	StreamInfo = (private_protocol_info_t **)arg;
	while(1)
	{
		printf("usercount is %d\n",(*StreamInfo)->usercount);
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
				sleep(2);
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
}

void private_protocol_stop(private_protocol_info_t **pStreamInfo)
{
	printf("private_protocol_stop!!\n");
	int iRet=0;
	if(NULL==(*pStreamInfo)) return;
	(*pStreamInfo)->run = 0;	
	PP_CLOSE_FD((*pStreamInfo)->cmdSocketFd);	
	PP_CLOSE_FD((*pStreamInfo)->streamSocketFd);
	iRet = CreatThread(private_protocol_free,(void *)(pStreamInfo));
	if(iRet != 0)
	{
		printf("CreatThread failed!\n");
		return -1;
	}	
    

}

void private_protocol_heartbeat(private_protocol_info_t *arg )
{
	if(arg == NULL)
	{
		return -1;
	}
	int iRet=0;
	iRet = CreatThread(private_protocol_sendHeartbeat,(void *)(arg));
	if(iRet != 0)
	{
		printf("CreatThread failed!\n");
		return -1;
	}
  	iRet = CreatThread(private_protocol_recvHeartbeat,(void *)(arg));
	if(iRet != 0)
	{
		printf("CreatThread failed!\n");
		return -1;
	}
}

void RecvOneFramedata(char *data,int datalen)
{
	static int totleLen = 0;
	static FILE *file = NULL;
	if(file == NULL)
	{
		file = fopen("video.save","w");
		if( NULL ==file)
		{
		    printf("open file failed!\n");
		    return;
		}
	}	
	
	totleLen += datalen;
        if(datalen!=fwrite(data,1,datalen,file))
	{
            printf("write file failed!\n");
            return;
        }
       // printf("recv totlen is %d, bufflen is %d\n",totleLen,datalen);
}

void recvStream( void *arg)
{
    if(arg==NULL)
    {
    	return -1;
    }
    char *buff = NULL;	
    private_protocol_info_t *streaminfo = NULL;
    streaminfo =	(private_protocol_info_t*)arg;	
    
    
    ARG_STREAM Stream;
    char recvstate=0;	
    int rsl;
    int recvLen;
    int buffLen = 0;
    int fd=0;
    fd = streaminfo->streamSocketFd;
   

    buff = malloc(MAX_FRAMESIZE);
    memset(buff,0x00,MAX_FRAMESIZE);	

    streaminfo->usercount++;		
    while(streaminfo->run){
        rsl = SK_SelectWait(fd,3000);
        if(0!=rsl) continue;

        recvLen = recv(fd,&Stream,ARG_HEAD_LEN,0);
        if(recvLen != ARG_HEAD_LEN){
            printf("recv head failed! len = %d\n",rsl);
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
        while(buffLen < Stream.bSize)
	{
		recvLen = recv(fd,buff+buffLen,Stream.bSize-buffLen,0);
		if(0==recvLen)
		{
			PP_FREE(buff);
			PP_CLOSE_FD(streaminfo->streamSocketFd);
			streaminfo->usercount--; 	
			printf("recv stream failed!\n");
			return;
		}
		else if(-1==recvLen){
		    usleep(40*1000);
		    continue;
		}
		buffLen += recvLen;
	 }
		
        RecvOneFramedata(buff,Stream.bSize);
      
    }
    PP_FREE(buff);		
    if(recvstate <0)
    {
    	PP_CLOSE_FD(streaminfo->streamSocketFd);
    	//private_protocol_stop(&streaminfo);
    }
    streaminfo->usercount--; 	
    printf("stop recvStream!!\n"); 	
}

/*void recvStream(void *arg)
{
     private_protocol_info_t *streaminfo = NULL;
    streaminfo =	(private_protocol_info_t*)arg;	
    char *buff = malloc(10*1024*1024);
    ARG_STREAM Stream;
    int rsl,fd;
    int recvLen;
    int buffLen = 0;
    int totleLen = 0;
    fd = streaminfo->streamSocketFd;
    FILE *file = fopen("video.save","wb+");
    if(0==file){
        printf("open file failed!\n");
        return;
    }

    while(1){
        rsl = SK_SelectWait(fd,3000);
        if(0!=rsl) continue;

        recvLen = recv(fd,&Stream,ARG_HEAD_LEN,0);
        if(recvLen != ARG_HEAD_LEN){
            printf("recv head failed! len = %d\n",rsl);
            break;
        }
        buffLen = 0;
        printf("must recv size %d\n",Stream.bSize);
        while(buffLen < Stream.bSize){
            recvLen = recv(fd,buff+buffLen,Stream.bSize-buffLen,0);
            if(0==recvLen) return;
            if(-1==recvLen){
                usleep(40*1000);
                continue;
            }
            buffLen += recvLen;
        }
        totleLen += Stream.bSize;
       if(Stream.bSize!=fwrite(buff,1,Stream.bSize,file)){
           printf("write file failed!\n");
            return;
       }
        printf("recv totlen is %d, bufflen is %d\n",totleLen,Stream.bSize);
    }
}*/


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


/*
 * ÏòÉè±¸·¢ËÍÐÄÌøÏûÏ¢
*/
/*void private_protocol_sendHeartbeat(void *arg)
{
	private_protocol_info_t * pInfo=NULL;
	pInfo =(private_protocol_info_t *)arg; 	
	char buff[ARG_BUFF_LEN];
	time_t      m_lastRegisterTime = 0;	
	ARG_CMD *pCmd = (ARG_CMD*)buff;

	struct timeval timeout;
	int i,result;

	pCmd->ulFlag = ARG_CMD_HEAD;
	pCmd->ulVersion = ARG_SDK_VERSION_1_1;
	pCmd->usCmd = CMD_ACT_HEADRTBEAT;
  
	while (pInfo->run)
	{
		time_t now = time(NULL);
		if(now - m_lastRegisterTime > 3)
		{
			 if(pInfo->cmdSocketFd > 0)
			 {
				pCmd->ulID =pInfo->userId;
				result = Sendmsg(pInfo->cmdSocketFd,(void*)pCmd,ARG_HEAD_LEN);
				if(result<0)
				{
					 PP_CLOSE_FD(pInfo->cmdSocketFd);	
				}
				
				m_lastRegisterTime = now;

				int rsl = SK_SelectWait(pInfo->cmdSocketFd,3000);
				if(rsl !=0)
				{
					continue;
				}
				printf("send heartbeat cmd!\n");
			 }	
		}
	  	    
	}
}*/

void private_protocol_sendHeartbeat(void *arg)
{
    private_protocol_info_t * pInfo=NULL;
    pInfo =(private_protocol_info_t *)arg; 	
    char buff[ARG_BUFF_LEN];
    ARG_CMD *pCmd = (ARG_CMD*)buff;

    struct timeval timeout;
    int i,count=0;

    pCmd->ulFlag = ARG_CMD_HEAD;
    pCmd->ulVersion = ARG_SDK_VERSION_1_1;
    pCmd->usCmd = CMD_ACT_HEADRTBEAT;
    pInfo->usercount++;
    while (pInfo->run)
    {
       timeout.tv_sec = 4;
       timeout.tv_usec = 0;

        
	if(1==pInfo->isWaitHeartbeatReply)
	{
		//printf("continue wait\n");
		if(count>2)
		{
			private_protocol_stop(&pInfo);
			break;
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
			pCmd->ulID =pInfo->userId;
			Sendmsg(pInfo->cmdSocketFd,(void*)pCmd,ARG_HEAD_LEN);
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
	select(0,0,0,0,&timeout);	
    }
    pInfo->usercount--;	
    printf("stop sendHeartbeat\n");	
}

void private_protocol_recvHeartbeat(void *arg)
{
    private_protocol_info_t * pInfo=NULL;
    pInfo =(private_protocol_info_t *)arg; 	
    char buff[ARG_BUFF_LEN];
    ARG_CMD *pCmd = (ARG_CMD*)buff;
    int i,recvLen;

    pCmd->ulFlag = ARG_CMD_HEAD;
    pCmd->ulVersion = ARG_SDK_VERSION_1_1;
    pCmd->usCmd = CMD_ACT_HEADRTBEAT;

    pInfo->usercount++; 	
    while (pInfo->run)
    {

	int result = SK_SelectWait(pInfo->cmdSocketFd,4000);  
	if(result !=0)
	{
		//printf("SK_SelectWait continue\n");
		continue;
	}
	
	if(1 == pInfo->isWaitReply)
	{
	        printf("waiting cmd, skip...\n");
	        usleep(10*1000);
	        continue;
        }
	recvLen = recv(pInfo->cmdSocketFd,(void*)pCmd,ARG_HEAD_LEN,0);
	if(ARG_HEAD_LEN != recvLen) continue;
	if(pCmd->ulBufferSize>0)
	{
	    recv(pInfo->cmdSocketFd,(void*)(buff+ARG_HEAD_LEN),pCmd->ulBufferSize,0);
	}
	/*if(pCmd->usCmd == CMD_ACT_HEADRTBEAT)
	{
	    printf("get heartbet response! rsl =%u\n",pCmd->ucState);
	}*/
	pInfo->isWaitHeartbeatReply = 0;

    }
    pInfo->usercount--;	
    printf("stop recvHeartbeat\n");	
}


int private_protocol_sendCmd(private_protocol_info_t* pStreamInfo, int cmdType, char *inData, int inLen, char *outData, int *outLen)
{
   
    char buff[ARG_BUFF_LEN] = {0};
    ARG_CMD *cmd = (ARG_CMD *)buff;

    int socketFd;
    int rsl;

    //å¦‚æžœåˆ«çš„çº¿ç¨‹çœŸæ­£å‘é€æˆ–ç­‰å¾…å‘½ä»¤åˆ™è¿”å›žå¤±è´¥
  
    if(0== pStreamInfo) return -1;
    if(pStreamInfo->isWaitReply) return -1;
	
    socketFd = (CMD_GET_STREAM==cmdType) ? pStreamInfo->streamSocketFd : pStreamInfo->cmdSocketFd;
    if(0>socketFd) return -1;

    cmd->ulFlag = ARG_CMD_HEAD;
    cmd->ulVersion = ARG_SDK_VERSION_1_1;
    cmd->usCmd = cmdType;
    cmd->ulID = pStreamInfo->userId;
    cmd->ulBufferSize = inLen;
    if(cmd->ulBufferSize > 0){
        memcpy(buff+ARG_HEAD_LEN,(void*)inData,cmd->ulBufferSize);
    }

    do{
        //·¢ËÍÇëÇóÐÅÁî£¬µÈ´ý¶ÔÓ¦ÏìÓ¦£¬Èç¹û½ÓÊÕµ½ÁËÐÄÌø»Ø¸´ÐÅÁî£¬Ôò¼ÌÐø½ÓÊÕ¶ÔÓ¦ÏìÓ¦
         pStreamInfo->isWaitReply = 1;
         rsl = send(socketFd,(void*)buff,ARG_HEAD_LEN+cmd->ulBufferSize,0);
        if(rsl != (int)(ARG_HEAD_LEN+cmd->ulBufferSize)){
            PRIVATE_LOG("send data failed! rsl = %d",rsl);
            break;
        }

	while(1)
	{

		rsl = SK_SelectWait(socketFd,3000);
	        if(0!=rsl) 
		{
			 goto RETURN_FAULT;
		};
		rsl = recv(socketFd,(void*)cmd,ARG_HEAD_LEN,0);
		if(ARG_HEAD_LEN != rsl)
		if(0!=rsl) 
		{
			 goto RETURN_FAULT;
		};
			
	        if(cmd->ulBufferSize>0){
	            rsl = recv(socketFd,(void*)(buff+ARG_HEAD_LEN),cmd->ulBufferSize,0);
	           // if(cmd->ulBufferSize != (unsigned long)rsl) break;  //ÒòÎªDVRÄÇ±ß¸øÁË³¤¶È¹ýÀ´È»ºóÓÖ²»·¢Êý¾Ý¹ýÀ´£¬ËùÒÔÎªÁËÅäºÏDVRÄÇ±ßµÄ°æ±¾£¬ÔÝÊ±ÆÁ±Î´Ë¼ì²â
	        }

	        if(cmd->ulBufferSize>0)
		{
		    if(rsl>0)
		    {
		    	  if(outData!=0) memcpy((void*)outData,(void*)(buff+ARG_HEAD_LEN),cmd->ulBufferSize);
	          	  if(outLen!=0) *outLen = cmd->ulBufferSize;
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
			continue;     //Èç¹û½ÓÊÕµ½µÄÊÇÐÄÌøÏìÓ¦£¬Ôò¼ÌÐø½ÓÊÕ	
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
        DES_Encode((char*)userInfo.ucPassWord,passwdBuff,serialNum,16);
        DES_Encode((char*)userInfo.ucSerialNum,serialNum,serialNum,ARG_SERIALNUM_LEN);
        rsl = private_protocol_sendCmd(pStreamInfo,CMD_ACT_LOGIN,(char*)&userInfo,sizeof(USER_INFO),0,0);
        if(0!=rsl) break;

        printf("login success uid is %lu\n",pStreamInfo->userId);

	pStreamInfo->run = 1;
	private_protocol_heartbeat(pStreamInfo);
		
        return 0;
    }while(0);

    printf("login failed!\n");
    PP_CLOSE_FD(pStreamInfo->cmdSocketFd);
    PP_CLOSE_FD(pStreamInfo->streamSocketFd);	
      
    pStreamInfo->ip = 0;
    pStreamInfo->port = 0;
    pStreamInfo->userId = 0;

    return -1;
}

//channelNo:Òª²¥·ÅµÄµÚ¼¸Í¨µÀ(´Ó0¿ªÊ¼), streamNo:0-Ö÷ÂëÁ÷,1-¸¨ÂëÁ÷

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
        printf("get stream success!\n");

        return 0;
    }while(0);
    printf("get tream failed! rsl = %d\n",rsl);
    PP_CLOSE_FD(pStreamInfo->streamSocketFd);
    return -1;
}


int SK_ConnectTo(unsigned int ip,int port)
{
    struct sockaddr_in address;

    int sockfd;
    int flags;
    int rsl;

    sockfd = socket(AF_INET,SOCK_STREAM,0);
    if(-1==sockfd) return -1;

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = ip;
    address.sin_port = htons(port);

    rsl = connect(sockfd,(const struct sockaddr *)&address,sizeof(struct sockaddr_in));
    if(0!=rsl){
        PP_CLOSE_FD(sockfd);
        return -1;
    }

    flags = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);
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


