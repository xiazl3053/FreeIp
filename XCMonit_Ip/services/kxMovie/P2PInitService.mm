//
//  P2PInitService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/18.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "P2PInitService.h"
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
@interface P2PInitService()
{
    P2PSDKClient* mSdk;
}
@end
@implementation P2PInitService

DEFINE_SINGLETON_FOR_CLASS(P2PInitService);

-(P2PSDKClient*)getP2PSDK
{
    if (!mSdk)
    {
        mSdk = P2PSDKClient::CreateInstance();
    }
    return mSdk;
}

-(void)setP2PSDKNull
{
    if (mSdk)
    {
        P2PSDKClient::DestroyInstance(mSdk);
    }
    mSdk = NULL;
}
-(NewQueue *)NewQueue
{
    NewQueue *que=NULL;
    if(que)
    {
        [self free_queue:que];
    }
    que = [self init_queue:256*1024];
    return que;
}
-(NewQueue*)init_queue:(int)size
{
    NewQueue *queue = NULL;
    printf("queue size:%lu!!!\n",sizeof(NewQueue));
    queue = (NewQueue*)malloc(sizeof(NewQueue));
    if(!queue)
        return NULL;
    pthread_mutex_init(&queue->locker, NULL);
    queue->buf = (uint8_t*)malloc(size);
    if(!queue->buf)
        return NULL;
    queue->read_ptr = queue->write_ptr = 0;
    queue->bufsize = size;
    return queue;
}

-(void)put_queue:(NewQueue*)que buf:(uint8_t*)buf size:(int)size
{
    unsigned char* dst = NULL;
    if(!que || !buf)
    {
        return ;
    }
    dst = que->buf + que->write_ptr;
    pthread_mutex_lock (&que->locker);
    if ((que->write_ptr + size) > que->bufsize)
    {
        memcpy(dst, buf, (que->bufsize - que->write_ptr));
        memcpy(que->buf, buf+(que->bufsize - que->write_ptr), size-(que->bufsize - que->write_ptr));
    } else
    {
        if(dst != NULL)
        {
            if((buf+size) != NULL)
            {
                memcpy(dst, buf, size);
            }
        }
    }
    que->write_ptr = (que->write_ptr + size) % que->bufsize;
    pthread_mutex_unlock (&que->locker);
}
-(int)get_queue:(NewQueue*)que buf:(uint8_t*)buf size:(int)size
{
    uint8_t* src = NULL;
    int wrap = 0;
    int pos = 0;
    if(!que || !buf)
    {
        return -1;
    }
    src = que->buf + que->read_ptr;
    pthread_mutex_lock (&que->locker);
    if(que->read_ptr > que->write_ptr)
    {
        if( (que->bufsize - (que->read_ptr - que->write_ptr)) < size )
        {
            pthread_mutex_unlock (&que->locker);
            return -1;
        }
    }else{
        if( (que->write_ptr - que->read_ptr) < size){
            pthread_mutex_unlock (&que->locker);
            return -1;
        }
    }
    pos  = que->write_ptr;
    if (pos < que->read_ptr) {
        pos += que->bufsize;
        wrap = 1;
    }
    if ( (que->read_ptr + size) > pos)
    {
        pthread_mutex_unlock (&que->locker);
        return 1;
    }
    if (wrap) {
        if(size > (que->bufsize-que->read_ptr))
        {
            memcpy(buf, src, (que->bufsize - que->read_ptr));
            memcpy(buf+(que->bufsize - que->read_ptr), src+(que->bufsize - que->read_ptr), size-(que->bufsize - que->read_ptr));
        }else
        {
            memcpy(buf, src, sizeof(uint8_t)*size);
        }
    } else
    {
        memcpy(buf, src, sizeof(uint8_t)*size);
    }
    que->read_ptr = (que->read_ptr + size) % que->bufsize;
    pthread_mutex_unlock (&que->locker);  
    return 0;
}
-(void)free_queue:(NewQueue*)que
{
    if(!que)
    {
        return ;
    }
    if(&que->locker)
    {
        pthread_mutex_destroy(&que->locker);
    }
    if(que->buf)
    {
        free(que->buf);
    }
    que->buf = NULL;
    free(que);
    DLog(@"释放QUEUE");
    que = NULL;
}

-(BOOL)getIPWithHostName:(const NSString *)hostName
{
    const char *hostN= [hostName UTF8String];
    struct hostent* phot;
    @try
    {
        phot = gethostbyname(hostN);
    }
    @catch (NSException *exception)
    {
        return NO;
    }
    struct in_addr ip_addr;
    if(phot)
    {
        memcpy(&ip_addr, phot->h_addr_list[0], 4);
        char ip[20] = {0};
        inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
        _strAddress = [NSString stringWithUTF8String:ip];
        
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
