//
//  P2PSDKService.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-14.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#ifndef __XCMonit_Ip__P2PSDKService__
#define __XCMonit_Ip__P2PSDKService__
#import <Foundation/Foundation.h>
#import "P2PSDKClient.h"
#import "P2PInitService.h"

using namespace std;

bool daemonize()
{
#ifdef WIN32
    // fork is not possible on Windows
    return false;
#else
    
    return true;
#endif
}


//#define PLAY_REAL 0

typedef struct struVideo
{
    int nSize;
    unsigned char cData[100*1024];
}struVideo;


class RecvFile : public EventHandler
{
public:
    RecvFile(P2PSDKClient* sdk, int type,int channel):mSdk(sdk),totalLen(0),conn(NULL),relayconn(NULL),streamType(type),nChannel(channel){bDevDisConn = NO;
        sendheartinfoflag = YES;bExit=NO;mReciveQueue = NULL;bRecord = NULL;bFirst=NO;};
    void thread();
    virtual bool ProcessFrameData(char* aFrameData, int aFrameDataLength);
    virtual bool DeviceDisconnectNotify();
    virtual bool RecordEndNotify(char* aNotifyData, int aNotifyDataLength);
    void StopRecv();
    void backword();
    void forword();
	void pause();
	void seek();
    BOOL connectTranServer(int nCodeType);
	void pause2play();
    BOOL startGcd(int _nType,int nCodeType);
    BOOL testConnection();
    //转发服务器
    BOOL tranServer(int nCodeType);
    BOOL sendHeart();
    int initP2PParam();
    BOOL connectP2PStream(int nCodeType);
    int initTranServer();
    void deleteP2PConn();
    void startRecord(CGFloat fStart,const char * cPath,const char *cDevName);
    void stopRecord(CGFloat fEnd,long lFrameNumber,int nBit);
    //码流切换
    BOOL swichCode(int nType);
    int getRealType();
    
    BOOL threadP2P(int nCodeType);
    BOOL threadTran(int nCodeType);
    void closeTran();
    void closeP2P();
    long nFrameNum;
    void sendPtzControl(PtzControlMsg *ptzMsg);
    
public:
    int nChannel;
    int nCode;
    BOOL bStart;
    NSFileHandle * fileHandle;
    BOOL bRecord;
    BOOL sendheartinfoflag;
    P2PSDKClient* mSdk;
    int totalLen;
    Connection* conn;
    RelayConnection* relayconn;
    int streamType;
    string peerName;
    NSMutableData *data;
    NSMutableArray *aryVideo;
    
    FILE *file_record;
    NSString *strFile;
    NSDate *startTime;
    NSDate *endTime;
    NSString *strDir;
    CGFloat start,end;
    BOOL bFirst;
    char cStart[32];
    char cEnd[32];
    char cFileName[512];
    char cRecordPath[32];
    char cDevName[32];
    NSString *testPath;
    NSMutableData *aryData;
    dispatch_queue_t _dispath;
    BOOL bDevDisConn;
    BOOL bExit;
    NewQueue *mReciveQueue;
};



#endif /* defined(__XCMonit_Ip__P2PSDKService__) */
