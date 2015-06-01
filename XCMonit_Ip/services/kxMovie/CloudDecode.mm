//
//  CloudDecode.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/27.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "CloudDecode.h"
#import "P2PSDK_New.h"
#import "P2PInitService.h"


extern "C"
{
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
}
@interface CloudDecode()
{
    P2PSDK_New *sdkNew;
    int _nChannel;
    NSString *_strNO;
    int nStreamType;
    
    
    
}
@end



@implementation CloudDecode

-(id)initWithCloud:(NSString*)strNo channel:(int)nChannel codeType:(int)nCode
{
    self = [super init];
    
    _nChannel = nChannel;
    _strNO = strNo;
    nStreamType = nCode;
    
    __weak CloudDecode *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [__self newSdkInfo];
    });
    
    return self;
}

-(void)newSdkInfo
{
    P2PSDKClient *sdk = [[P2PInitService sharedP2PInitService] getP2PSDK];
    if(!sdk)
    {
        DLog(@"初始化失败");
        return ;
    }
    sdkNew = new P2PSDK_New(sdk,0,_nChannel);
    
    sdkNew->peerName = [_strNO UTF8String];
    __weak CloudDecode *__self = self;
    dispatch_async(dispatch_get_global_queue(0,0 ), ^{
        [__self thread_p2p];
    });
    dispatch_async(dispatch_get_global_queue(0,0 ), ^{
        [__self thread_tran];
    });
}

-(void)thread_p2p
{
    BOOL bFlag = sdkNew->initP2PServer();
    if (bFlag)
    {
        struct _playrecordmsg recordreq;
        char responsedata[MAX_MSG_DATA_LEN];
        recordreq.channelNo = 1;
        recordreq.frameType = 0;
        recordreq.startTime = 5200;
        recordreq.endTime = 9000;
        recordreq.nalarmFileType = 1;
        sdkNew->P2P_RecordSearch(&recordreq,responsedata);
    }
}

-(void)thread_tran
{
    BOOL bFlag = sdkNew->initTranServer();
    if (bFlag)
    {
        struct _playrecordmsg recordreq;
        char  responsedata[MAX_MSG_DATA_LEN];
        recordreq.channelNo = 1;
        recordreq.frameType = 0;
        recordreq.startTime = 5200;
        recordreq.endTime = 9000;
        recordreq.nalarmFileType = 1;
        sdkNew->TRAN_RecordSerach(&recordreq, responsedata);
    }
}

-(NSMutableArray*)getCloudInfo:(NSDate*)dateTime
{
    return nil;
}

-(BOOL)playDeviceCloud:(NSDate*)dateTime
{
    return NO;
}

@end
