


#include "DIrectDVR.h"
#include <stdio.h>
#include "unistd.h"

#define MAIN_VIDEOBUFF_LEN  (1*1024*1024)
int recvStream(int sockfd)
{
    ARG_STREAM     stream;
    char           pBuff[MAIN_VIDEOBUFF_LEN];

    int            len;
    int            rsl;
    if(0>sockfd) return -1;
    int            frameNum=0;
    UInt32  size;
    while(1)
    {
        rsl = SK_SelectWaitReadable(sockfd,3000);
        if(0==rsl)
        {
            len = recv(sockfd,&stream,sizeof(ARG_STREAM),0);
            if(0>len) continue;
            if(sizeof(ARG_STREAM)!=len){
                printf("read head failed!\n");
                break;
            }
        }
        len = 0;
        while(len < stream.bSize){
            while(0!=SK_SelectWaitReadable(sockfd,3000));
            len += recv(sockfd,pBuff+len,stream.bSize-len,0);
        }
        if(100 <=frameNum) break;
        frameNum++;
        size += stream.bSize;
    }
    return size;
}


int  Recvmsg(int* run,int msocket,char *buff,int datalen)
{
	int haverecvdatalen = 0;
	int totaldatalen = datalen;

	
	while(totaldatalen>0)
	{
		if(*run ==1)
		{
			int recvlen = recv(msocket,buff+haverecvdatalen,totaldatalen,0); //Ω” ’’Ê’˝µƒ«Î«Û ˝æ›
			if(recvlen> 0)
		        {   
				totaldatalen -= recvlen;
				haverecvdatalen += recvlen;
									           
		        }
			else  if ( recvlen< 0 && ( errno == EINTR || errno == EAGAIN ) )
			{
				//printf("errno == EINTR\n");
				usleep(50*1000);   //50ms
	 			continue;
			  
			}
			else
			{
				perror("Recvmsg recv  error\n");
				return -1;
			}	
		}
		else
		{
			printf("stop Recvmsg!!!\n");
			return -1;
		}
		
	}
	return 0;
}

void RecvOneFramedata(char *data,int datalen,void *arg)
{
    printf("datalen:%d\n",datalen);
    pteClient_t *pClient = (pteClient_t *)arg;
    NSMutableArray *aryVideo = (__bridge NSMutableArray*)pClient->aryVideo;
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
        @synchronized(aryVideo)
        {
            [aryVideo addObject:dataInfo];
        }
        dataInfo = nil;
    }
    free(pBuf);
    
}

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

void recvStream2(void * arg)
{
    if(arg == NULL)
    {
    	return ;
    }
    char *buff = NULL;	
    ARG_STREAM Stream;
    char recvstate=0;	
    int rsl;
    int recvLen;
    int fd = 0;
    int *fsocket=NULL;
   pteClient_t*  pclient = (pteClient_t*)arg;
   fd = pclient->sockFd;

    buff = malloc(MAIN_VIDEOBUFF_LEN);
    memset(buff,0x00,MAIN_VIDEOBUFF_LEN);	

    pclient->musercount++;
    while(pclient->run){
	     rsl = SK_SelectWaitReadable(fd,1000);
		 if(0!=rsl)
		 {
		 	printf("cotinue!\n");
			continue;
		 }	
		 int ret = Recvmsg(&pclient->run,fd,(char *)(&Stream),ARG_HEAD_LEN);
		 if(ret <0)
		 {
			    printf("Recvmsg head failed\n");
			    recvstate = -1;		
		            break;
		 }
         if(Stream.bSize>MAIN_VIDEOBUFF_LEN)
         {
        	printf("Stream.bSize is %d\n",Stream.bSize);
        	PTE_FREE(buff);	
    		buff = malloc(Stream.bSize);
      		memset(buff,0x00,Stream.bSize);
         }
    	 int result = Recvmsg(&pclient->run,fd,buff,Stream.bSize);
    	 if(result<0)
    	 {
    	 	break;
    	 }
    	 if(Stream.bMediaType == VEDIO_FRAME)	  //»Áπ˚ « ”∆µ¡˜µƒª∞£¨Õ®÷™…œ≤„»° ˝æ›
         {
    		RecvOneFramedata(buff,Stream.bSize,pclient);
    	 }
    }
    pclient->musercount--;	
    PTE_FREE(buff);
    
    printf("stop recvStream!!\n");
    return ;
}

int  StartGetStream(void *arg)
{
	if(arg == NULL)
	{
		printf("StartGetStream arg is NULL!!!\n");
		return -1;
	}
	int iRet=0;
	pteClient_t* pclient = (pteClient_t*)arg;
	pclient->run = 1;

	iRet = CreatThread(recvStream2,(void *)(arg));
	if(iRet != 0)
	{
		printf("CreatThread failed!\n");
		return -1;
	}
	printf("StartGetStream return!!!\n");
    return 0;
}

void testFunf(int ip, int port, USER_INFO *pUserInfo, int channel, int streamType)
{
    pteClient_t *pClient;
    int rsl;
    unsigned int size;
    do{

        pClient = PC_CreateNew();
        if(0==pClient) break;

        while(1){
            rsl = PC_Login(pClient,ip,port,pUserInfo);
            if(0==rsl){
                printf("login success--------------------------------\n");
                break;
            }else{
                printf("login failed++++++++++++++++++++++++++++++++++\n");
            }
            sleep(1);
        }
        rsl = PC_GetStream(pClient,channel,streamType);
        if(0==rsl)
        {
            size = recvStream(pClient->sockFd);
            printf("ip %s, ch=%d,t=%d, 100 frame size is %d, reconnect\n",inet_ntoa(*(struct in_addr*)&ip),channel,streamType,size);
            printf("get stream success------------------------\n");
        }else{
            printf("get stream failed+++++++++++++++++++++++++++\n");
        }

        sleep(1);
        PC_Delete(pClient);
        pClient = 0;
        continue;
        printf("pte client success!\n");
        return;
    }while(1);
    printf("pte client falid!\n");
    return;
}

void test1()
{


    USER_INFO userInfo;

    memset(&userInfo,0,sizeof(USER_INFO));
    snprintf((char*)userInfo.ucUsername,sizeof(userInfo.ucUsername),"admin");
    snprintf((char*)userInfo.ucPassWord,sizeof(userInfo.ucPassWord),"admin");


    testFunf(inet_addr("172.18.195.208"),12241,&userInfo,0,1);
    printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
}


void test2()
{
    USER_INFO userInfo;

    memset(&userInfo,0,sizeof(USER_INFO));
    snprintf((char*)userInfo.ucUsername,sizeof(userInfo.ucUsername),"admin");
    snprintf((char*)userInfo.ucPassWord,sizeof(userInfo.ucPassWord),"admin");

    testFunf(inet_addr("172.18.195.208"),12241,&userInfo,0,0);


    printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
}

int Direct_Connect(pteClient_t *pClient,Direct_UserInfo *directInfo,int nStream,int nChannel)
{
    int rsl=-1;
//    printf("UInt32 size is %lu\n",sizeof(UInt32));
//    pteClient_t *pClient;
//    rsl = PC_InitCtx();
//    if(0!=rsl)
//    {
//        return DIRECT_CONNECT_INIT_FAIL;
//    }
//    pClient = PC_CreateNew();
//    if(0==pClient)
//    {
//        return DIRECT_CONNNECT_NEW_FAIL;
//    }
//    rsl = PC_Login(pClient,inet_addr((char*)&directInfo->cAddress),directInfo->nPort,&(directInfo->userinfo));
//    USER_INFO *user = (USER_INFO*)malloc(sizeof(user));
//    sprintf((char *)&user->ucUsername, "admin");
//    sprintf((char *)&user->ucPassWord, "12345");
    rsl = PC_Login(pClient,inet_addr((char*)&directInfo->cAddress),directInfo->nPort,&directInfo->userinfo);
    if(0==rsl)
    {
        printf("PC_Login success!\n");
    }
    else
    {
      	printf("PC_Login failed!\n");
//        PC_Delete(pClient);
//        PC_UnInitCtx();
        return DIRECT_CONNECT_LOGIN_FAIL;
    }
    rsl = PC_GetStream(pClient,nChannel,nStream);
    if(0==rsl)
    {
        printf("get stream success\n");
        rsl = StartGetStream(pClient);
        if(0!=rsl)
        {
            printf("StartGetStream failed!!!\n");
            return  DIRECT_CONNECT_GET_STREAM_FAIL;
        }
    }
    else
    {
    	printf("PC_GetStream failed!!!\n");
//        PC_Delete(pClient);
//        PC_UnInitCtx();
        return DIRECT_CONNECT_GET_STREAM_FAIL;
    }
    return DIRECT_CONNECT_SUCESS;
}

void destoryClient(pteClient_t *pClient)
{
    PC_Delete(pClient);
}

