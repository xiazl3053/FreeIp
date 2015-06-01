//
//  DIrectDVR.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/6/1.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#ifndef XCMonit_Ip_DIrectDVR_h
#define XCMonit_Ip_DIrectDVR_h
#include "pteClient.h"
#include "agreement.h"

typedef enum DIRECT_CONNECT
{
    DIRECT_CONNECT_SUCESS = 0,
    DIRECT_CONNECT_INIT_FAIL,
    DIRECT_CONNNECT_NEW_FAIL,
    DIRECT_CONNECT_LOGIN_FAIL,
    DIRECT_CONNECT_GET_STREAM_FAIL
}DIRECT_CONNECT;

typedef struct Direct_UserInfo
{
    int nPort;
    char cAddress[32];
    USER_INFO userinfo;
}Direct_UserInfo;

int Direct_Connect(pteClient_t *pClient,Direct_UserInfo *directInfo,int nStream,int nChannel);

void destoryClient(pteClient_t *pClient);

#endif
