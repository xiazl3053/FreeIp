//
//  P2PInitService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/18.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UtilsMacro.h"
#include "P2PSDKClient.h"
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>

typedef struct{
    pthread_mutex_t locker;
    uint8_t* buf;
    int bufsize;
    int write_ptr;
    int read_ptr;
}NewQueue;

@interface P2PInitService : NSObject

DEFINE_SINGLETON_FOR_HEADER(P2PInitService);

@property (nonatomic,strong) NSString *strAddress;

-(P2PSDKClient*)getP2PSDK;
-(void)setP2PSDKNull;
-(NewQueue *)NewQueue;


-(BOOL)getIPWithHostName:(const NSString *)hostName;
-(void)put_queue:(NewQueue*)que buf:(uint8_t*)buf size:(int)size;
-(int)get_queue:(NewQueue*)que buf:(uint8_t*)buf size:(int)size;
-(void)free_queue:(NewQueue*)que;

@end



