//
//  P2PSDK_New.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/27.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#ifndef __XCMonit_Ip__P2PSDK_NEW__
#define __XCMonit_Ip__P2PSDK_NEW__
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


class P2PSDK_New : public EventHandler
{
public:
    P2PSDK_New(P2PSDKClient* sdk, int type,int channel):mSdk(sdk),conn(NULL),relayconn(NULL),streamType(type),nChannel(channel){
        };
    void thread();
    virtual bool ProcessFrameData(char* aFrameData, int aFrameDataLength);
    virtual bool DeviceDisconnectNotify();
    virtual bool RecordEndNotify(char* aNotifyData, int aNotifyDataLength);
    void StopRecv();
    
    int  P2P_GetDeviceRecordInfo(struct _playrecordmsg*   recordsearch_req,struct  _playrecordresp*  recordsearch_resp);
    int  RELAY_GetDeviceRecordInfo(struct _playrecordmsg*   recordsearch_req,struct  _playrecordresp*  recordsearch_resp);
    
    int  P2P_PlayDeviceRecord(struct _playrecordmsg*   playrecord_req);
    int  RELAY_PlayDeviceRecord(struct _playrecordmsg*   playrecord_req);
    
    int  P2P_RecordSearch(struct _playrecordmsg*   recordsearch_req,char*  resp);
    int  TRAN_RecordSerach(struct _playrecordmsg*   recordsearch_req,char*  resp);
    
    int closeTranServer();
    int closeP2PService();
    
    int stopDeviceRecord(struct _playrecordmsg*   playrecord_req);
    
    BOOL initP2PServer();
    BOOL initTranServer();
    
    int controlDeviceRecord(PlayRecordCtrlMsg *control);
    
    int  P2P_RecordDrag(RecordDragMsg* recorddragmsg);
    int  RELAY_RecordDrag(RecordDragMsg* recorddragmsg);
    
    void startRecord(const char * cPath,const char *cRecordDevName);
    void clearVideoInfo();
    void stopRecord(int nBit);
public:
    int nChannel;
    NSString *strFile;
    NSString *strDir;
    NSFileHandle *fileHandle;
    int nNumberCatch;
    BOOL bStart;
    BOOL bRecord;
    char cRecordPath[512];
    char cDevName[512];
    char cStart[80];
    char cEnd[80];
    char cFileName[80];
    BOOL bFirst;
    int nFrameNum;
    
    
    
    
    P2PSDKClient* mSdk;
    Connection* conn;
    RelayConnection* relayconn;
    int streamType;
    string peerName;
    NSMutableData *data;
    NSMutableArray *aryVideo;
    NSMutableData *aryData;
};

#endif

