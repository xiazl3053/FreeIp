
//
//  P2PSDKService.cpp
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-14.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#include "P2PSDKService.h"
#include <stdio.h>
#import <Foundation/Foundation.h>
#import "XCNotification.h"
#import "P2PInitService.h"
#import "RecordModel.h"
#import "RecordDb.h"
using namespace std;

#define P2PSHAREDSERVICE  [P2PInitService sharedP2PInitService]
#define HEART_SECOND   30
bool RecvFile::ProcessFrameData(char* aFrameData, int aFrameDataLength)
{
    unsigned char* pUnData=(unsigned char*)aFrameData;
    unsigned char* pBuf = (unsigned char*)malloc(256);
    int nTemp = 256;
    int nCurSize = 0,nRead = 0;
    //每次读取256个字节
    while (nCurSize!=aFrameDataLength)
    {
        nRead = ((aFrameDataLength - nCurSize) > nTemp) ? nTemp : (aFrameDataLength - nCurSize);
        memcpy(pBuf, pUnData+nCurSize, nRead);
        nCurSize +=nRead;
        NSData *dataInfo = [[NSData alloc] initWithBytes:pBuf length:nRead];
        @synchronized(aryVideo)
        {
            [aryVideo addObject:dataInfo];
        }
        dataInfo = nil;
    }
    free(pBuf);
    
    if (bRecord)
    {
        [data appendBytes:pUnData length:aFrameDataLength];
    }
    return true;
}
bool RecvFile::DeviceDisconnectNotify()
{
    printf("device is disconnect\n");
    if (!conn)
    {
        bDevDisConn = YES;
        StopRecv();
    }
    else if(!relayconn)
    {
        bDevDisConn = YES;
        StopRecv();
    }else
    {
        bDevDisConn = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:@"设备连接丢失"];
    }
    return true;
}
void RecvFile::StopRecv()
{
    sendheartinfoflag = NO;
    bDevDisConn = YES;
    if (conn)
    {
        if(streamType == 0)
        {
            int ret = conn->StopRealStream(nChannel, nCode);
            if(ret == 0)
            {
                printf("success stop real stream \n");
            }
            else
                printf("error stop real stream \n");
        }
        else if(streamType == 1)
        {
            PlayRecordCtrlMsg msg;
            msg.ctrl = PB_STOP;
            conn->PlayBackRecordCtrl(&msg);
        }
        conn->Close();
        delete conn;
        conn = NULL;
    }
    if(relayconn)
    {
        if(streamType == 0)
        {
            int ret = relayconn->StopRealStream(nChannel, nCode);
            
            if(ret == 0)
            {
                printf("success stop relay stream \n");
            }
        }
        else if(streamType == 1)
        {
            PlayRecordCtrlMsg msg;
            msg.ctrl = PB_STOP;
            relayconn->PlayBackRecordCtrl(&msg);
        }
        relayconn->Close();
        delete relayconn;
        relayconn = NULL;
    }
}
void RecvFile::backword()
{
    PlayRecordCtrlMsg msg;
    msg.ctrl = PB_BACKWARD;
    conn->PlayBackRecordCtrl(&msg);
}
void RecvFile::forword()
{
    PlayRecordCtrlMsg msg;
    msg.ctrl = PB_FORWARD;
    conn->PlayBackRecordCtrl(&msg);
}
void RecvFile::pause()
{
    PlayRecordCtrlMsg msg;
    msg.ctrl = PB_PAUSE;
    conn->PlayBackRecordCtrl(&msg);
}
void RecvFile::seek()
{
    PlayRecordMsg msg;
    msg.channelNo = 0;
    msg.startTime = 1372219200;
    msg.endTime = 1372222800;
    conn->PlayBackRecord(&msg);
}
void RecvFile::pause2play()
{
    PlayRecordCtrlMsg msg;
    msg.ctrl = PB_PLAY;
    conn->PlayBackRecordCtrl(&msg);
}

BOOL RecvFile::testConnection()
{
    BOOL bReturn  = TRUE;
    if(conn == NULL)
    {
		conn = new Connection(this);
    }
    int ret = mSdk->Connect((char*)peerName.c_str(), conn); //œÚIPC¡¨Ω”
    if(ret != 0)
    {
        bReturn = FALSE;
    }
    return bReturn;
}


int RecvFile::initTranServer()
{
    mSdk->SendHeartBeat();
    if(relayconn == NULL)
    {
        if(!bExit)
        {
            relayconn = new RelayConnection(this);
        }
        if(!bExit)
        {
            int ret = mSdk->RelayConnect((char*)peerName.c_str(),relayconn);
            return ret;
        }
    }
    delete relayconn;
    relayconn = NULL;
    return -1;
    
}
BOOL RecvFile::connectTranServer(int nCodeType)
{
    int ret = 0;
    if(streamType == 0 && relayconn)
    {
        if(!bExit)
        {
            ret = relayconn->StartRealStream(nChannel, nCodeType);   //0 «Õ®µ¿∫≈,2 «∏®¬Î¡˜
            nCode = nCodeType;
            if(ret == 0)
            {
                DLog(@"StartRelayStream success \n");
            }
            else if(ret < 0)
            {
                DLog(@"StartRelayStream failed, ret=%d \n", ret);
                StopRecv();
                return FALSE;
            }
        }
    }
    return TRUE;
}

BOOL RecvFile::tranServer(int nCodeType)
{
    BOOL bReturn = TRUE;
    int ret = this->initTranServer();
    if(ret == 0)
    {
        DLog(@"sdk relayconnect success");
        if(this->connectTranServer(nCodeType))
        {
            _dispath = dispatch_queue_create("heart", 0);
            this->sendHeart();
        }else
        {
            sendheartinfoflag = FALSE;
            bReturn = FALSE;
        }
    }
    else
    {
        DLog(@"relayconnect failed");
        sendheartinfoflag = FALSE;
        delete relayconn;
        relayconn = NULL;
        bReturn = FALSE;
    }
    return bReturn;
}
//心跳线程
BOOL RecvFile::sendHeart()
{
    dispatch_async(_dispath, ^
    {
        int nNumber = 0;
        while(sendheartinfoflag)
        {
            while (sendheartinfoflag && nNumber< HEART_SECOND)
            {
                [NSThread sleepForTimeInterval:0.5];
                nNumber++;
            }
            nNumber = 0;
            mSdk->SendHeartBeat();
        }
        DLog(@"心跳销毁");
    });
   return YES;
}



/*P2P操作 1.初始化 2.成功就直接获取码流 connectP2PStream 3.失败，采用转发方式*/
int RecvFile::initP2PParam()
{
    if(conn == NULL)
    {
        if (!bExit)
        {
            conn = new Connection(this);
        }
    }
    if (!bExit)
    {
        return mSdk->Connect((char*)peerName.c_str(), conn);
    }
    return -1;
}
BOOL RecvFile::connectP2PStream(int nCodeType)
{
    int ret = 0;
    if(streamType == 0 && conn)
    {
        if(!bExit)
        {
            nCode = nCodeType;
            ret = conn->StartRealStream(nChannel, nCode);
        }
        if(ret != 0)
        {
            return FALSE;
        }
    }
    else if(streamType == 1)
    {
        PlayRecordMsg msg;
        msg.channelNo = 0;
        msg.startTime = 1373439705;
        msg.endTime = 1373439861;
        ret = conn->PlayBackRecord(&msg);
        if(ret != 0)
        {
            printf("PlayBackRecord failed \n");
            return FALSE;
        }
    }
    return TRUE;
}

void RecvFile::deleteP2PConn()
{
    if(conn != NULL)
    {
        delete conn;
        conn = NULL;
    }
}
BOOL RecvFile::startGcd(int _nType,int nCodeType)
{
    
    BOOL bReturn = TRUE;
    if(_nType==1)
    {

        int ret = this->initP2PParam();
        if(ret == 0)
        {
            bReturn = this->connectP2PStream(nCodeType);
        }
        else
        {
            DLog(@"P2P sdk fail ...    using transerver \n");
            this->deleteP2PConn();
            bReturn = this->tranServer(nCodeType);
        }
    }
    else if(_nType==2)
    {
        bReturn = this->tranServer(nCodeType);
    }
    if (bReturn)
    {
        aryVideo = [[NSMutableArray alloc] init];
    }
    return bReturn;
}
void RecvFile::stopRecord(CGFloat fEnd)
{
    if (!bRecord)
    {
        return ;
    }
    end = fEnd;
    if ([data writeToFile:strFile atomically:YES])
    {
        DLog(@"写入成功");
    }
    BOOL success = [[NSURL fileURLWithPath:strFile] setResourceValue: [NSNumber numberWithBool: YES]
                                                        forKey: NSURLIsExcludedFromBackupKey error:nil];
    if(!success)
    {
        NSLog(@"Error excluding文件");
    }
    NSDate *senddate=[NSDate date];
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
    NSString *  morelocationString=[dateformatter stringFromDate:senddate];
    DLog(@"结束时间:%@",morelocationString);
    //在数据库中加入纪录
    sprintf(cEnd, "%s",[morelocationString UTF8String]);
    RecordModel *record = [[RecordModel alloc] init];
    record.strDevNO = [NSString stringWithUTF8String:peerName.c_str()];
    record.strStartTime = [NSString stringWithUTF8String:cStart];
    record.strEndTime = [NSString stringWithUTF8String:cEnd];
    record.strFile = [NSString stringWithUTF8String:cFileName];
    
    NSDateFormatter *date=[[NSDateFormatter alloc] init];
    [date setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
    record.allTime = end-start;
    [RecordDb insertRecord:record];
    bRecord = NO;
    data = nil;
}
void RecvFile::startRecord(CGFloat fStart)
{
    start = 0;
    end = 0;
//  创建文件  获取系统时间  序列号  peerName
    NSDate *senddate=[NSDate date];
    start = fStart;
    //时间格式
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
    NSString *  morelocationString=[dateformatter stringFromDate:senddate];
    
    //保存文件路径
    NSDateFormatter  *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *filePath = [NSString stringWithFormat:@"%@.mp4",[fileformatter stringFromDate:senddate]];
    
    //创建一个目录
    NSString *strDir = [kLibraryPath  stringByAppendingPathComponent:@"record"];
    BOOL bFlag = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:strDir isDirectory:&bFlag])
    {
        DLog(@"目录不存在");
        [[NSFileManager defaultManager] createDirectoryAtPath:strDir withIntermediateDirectories:NO attributes:nil error:nil];
        BOOL success = [[NSURL fileURLWithPath:strDir] setResourceValue: [NSNumber numberWithBool: YES]
                                                                 forKey: NSURLIsExcludedFromBackupKey error:nil];
        if(!success)
        {
            NSLog(@"Error excluding不备份文件夹");
        }
    }
    //视频文件保存路径
    strFile  = [strDir stringByAppendingPathComponent:filePath];
    //开始时间与文件名
    sprintf(cStart, "%s",[morelocationString UTF8String]);
    sprintf(cFileName,"%s",[filePath UTF8String]);
    DLog(@"strFile:%@",strFile);
    if ([[NSFileManager defaultManager] createFileAtPath:strFile contents:nil attributes:nil])
    {
        DLog(@"创建文件成功:%@",strFile);
    }
    data = [[NSMutableData alloc] init];
    bFirst = NO;
    bRecord = YES;
}
BOOL RecvFile::swichCode(int nType)
{
    //先清空之前的码流
    @synchronized(aryVideo)
    {
        [aryVideo removeAllObjects];
    }
    int nRet = -1;
    DLog(@"通道切换:%d--%d",nChannel,nType);
    if (conn)
    {
        conn->StopRealStream(nChannel, nCode);
        [NSThread sleepForTimeInterval:2.0];
        nRet = conn->StartRealStream(nChannel, nType);
        nCode = nType;
    }
    else if(relayconn)
    {
        relayconn->StopRealStream(nChannel, nCode);
        [NSThread sleepForTimeInterval:2.0];
        nRet = relayconn->StartRealStream(nChannel, nType);
        nCode = nType;
    }
    DLog(@"nRet:%d",nRet);
    
    if (!nRet) {
        return YES;
    }
    return NO;
}


//  /var/mobile/Applications/CED00BC6-53A4-43F7-9307-8EFFBD6D0D8B/Library/450691550_2014-07-03-10-11-06.mp4

