
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

#define HEART_SECOND   30

bool RecvFile::ProcessFrameData(char* aFrameData, int aFrameDataLength)
{
    if( aFrameDataLength <= 0 )
    {
        return YES;
    }
    unsigned char *unFrame = (unsigned char *)aFrameData;
    DLog(@"%hhu--%hhu--%hhu--%hhu--%hhu--%d",unFrame[0],unFrame[1],unFrame[2],unFrame[3],unFrame[4],aFrameDataLength);
//    if (!aryData)
//    {
//        aryData = [NSMutableData data];
//        [aryData appendBytes:aFrameData length:aFrameDataLength];
//    }
//    else
//    {
//        if (unFrame[0] != 0x00 || unFrame[1] != 0x00)
//        {
//            [aryData appendBytes:aFrameData length:aFrameDataLength];
//            @synchronized(aryVideo)
//            {
//                [aryVideo addObject:aryData];
//            }
//        }
//        else
//        {
//            @synchronized(aryVideo)
//            {
//                [aryVideo addObject:aryData];
//            }
//            aryData = nil;
//            aryData = [NSMutableData data];
//            [aryData appendBytes:aFrameData length:aFrameDataLength];
//        }
//    }
//    if(unFrame[3] == 0x67 || unFrame[4] == 0x67)
//    {
//        aryData = [NSMutableData data];
//        [aryData appendBytes:aFrameData length:aFrameDataLength];
//    }
//    else if(unFrame[3] == 0x61 || unFrame[4] == 0x61)
//    {
//        NSData *dataInfo = [NSData dataWithBytes:aFrameData length:aFrameDataLength];
//        if(aryData)
//        {
//            @synchronized(aryVideo)
//            {
//                [aryVideo addObject:aryData];
//            }
//            aryData = nil;
//        }
//        @synchronized(aryVideo)
//        {
//            [aryVideo addObject:dataInfo];
//        }
//    }
//    else
//    {
//        [aryData appendBytes:aFrameData length:aFrameDataLength];
//    }
    NSData *dataInfo = [NSData dataWithBytes:aFrameData length:aFrameDataLength];
    @synchronized(aryVideo)
    {
        [aryVideo addObject:dataInfo];
    }
    dataInfo = nil;
    
    if (bRecord)
    {
        if(bStart)
        {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[[NSData alloc] initWithBytes:aFrameData length:aFrameDataLength]];
            if( aFrameData[3]==0x67 || aFrameData[4]==0x67 || aFrameData[3]==0x61 || aFrameData[4]==0x61)
            {
                nFrameNum ++;
            }
        }
        else
        {
            if( aFrameData[3]==0x67 || aFrameData[4]==0x67 )
            {
                nFrameNum = 0;
                bStart = YES;
                DLog(@"检测到 I frame");
                [fileHandle writeData:[[NSData alloc] initWithBytes:aFrameData length:aFrameDataLength]];
                nFrameNum++;
            }
        }
        
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
    }
    DLog(@"发送");
    [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"Disconnect")];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DISCONNECT object:[NSString stringWithFormat:@"%li",(long)nChannel]];
    
    return true;
}


void RecvFile::StopRecv()
{
    DLog(@"结束");
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
//            msg.ctrl = PB_STOP;
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
//            msg.ctrl = PB_STOP;
            relayconn->PlayBackRecordCtrl(&msg);
        }
        relayconn->Close();
        delete relayconn;
        relayconn = NULL;
    }
    stopRecord(0, 0, 25);
    [aryVideo removeAllObjects];
    aryVideo = nil;
}

void RecvFile::closeP2P()
{
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
//            msg.ctrl = PB_STOP;
            conn->PlayBackRecordCtrl(&msg);
        }
        conn->Close();
        delete conn;
        conn = NULL;
    }
}

void RecvFile::closeTran()
{
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
//            msg.ctrl = PB_STOP;
            relayconn->PlayBackRecordCtrl(&msg);
        }
        if(relayconn!=NULL)
        {
            relayconn->Close();
            delete relayconn;
            relayconn = NULL;
        }
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
    if (mSdk)
    {
        mSdk->SendHeartBeat();
    }
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
                if(!aryVideo)
                {
                    aryVideo = [NSMutableArray array];
                }
            }
            else if(ret < 0)
            {
                DLog(@"StartRelayStream failed, ret=%d \n", ret);
                closeTran();
                DLog(@"关闭转发");
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
        if(this->connectTranServer(nCodeType))//如果失败，connectTranServer有关闭转发的动作
        {
            
        }
        else
        {
            bReturn = NO;
        }
    }
    else
    {
        DLog(@"relayconnect init failed");
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
//    dispatch_async(_dispath, ^
//    {
//        int nNumber = 0;
//        while(sendheartinfoflag)
//        {
//            while (sendheartinfoflag && nNumber< HEART_SECOND)
//            {
//                [NSThread sleepForTimeInterval:0.5];
//                nNumber++;
//            }
//            nNumber = 0;
//            mSdk->SendHeartBeat();
//        }
//        DLog(@"心跳销毁");
//    });
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
    if (!bExit && mSdk)
    {
        
        if(mSdk->Connect((char*)peerName.c_str(), conn)==0)
        {
            DLog(@"P2P连接设备成功");
            return 0;
        }
        DLog(@"P2P连接设备失败");
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
            DLog(@"P2P无法接收码流");
            return FALSE;
        }
        DLog(@"P2P开始接收码流");
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
    if(!aryVideo)
    {
        aryVideo = [NSMutableArray array];
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

BOOL RecvFile::threadP2P(int nCodeType)
{
    BOOL bReturn = FALSE;
    int ret = this->initP2PParam();
    if(ret == 0)
    {
        bReturn = this->connectP2PStream(nCodeType);
    }
    if(!bReturn)
    {
        this->deleteP2PConn();
    }
    return bReturn;
}

BOOL RecvFile::threadTran(int nCodeType)
{
    BOOL bReturn = this->tranServer(nCodeType);
    if (bReturn)
    {
        return YES;
    }
    return NO;
}

void RecvFile::stopRecord(CGFloat fEnd,long lFrameNumber,int nBit)
{
    if (!bRecord)
    {
        return ;
    }
    bRecord = NO;
 //   end = fEnd-start;
    [fileHandle closeFile];//新加入的
    bStart = NO;
    BOOL success = [[NSURL fileURLWithPath:strFile] setResourceValue: [NSNumber numberWithBool: YES]
                                                        forKey: NSURLIsExcludedFromBackupKey error:nil];
    if(!success)
    {
        DLog(@"Error excluding文件");
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
    record.imgFile = [NSString stringWithUTF8String:cRecordPath];
    record.strDevName = [NSString stringWithUTF8String:cDevName];
    NSDateFormatter *date=[[NSDateFormatter alloc] init];
    [date setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
    record.allTime = 0;
    DLog(@"记录:%li--P2P记录:%li",lFrameNumber,nFrameNum);
    record.nFramesNum = nFrameNum;
    record.nFrameBit = nBit;
    DLog(@"fEnd:%f",end);
    [RecordDb insertRecord:record];
    data = nil;
}
void RecvFile::startRecord(CGFloat fStart,const char * cPath,const char *cRecordDevName)
{
    start = 0;
    end = 0;
//  创建文件  获取系统时间  序列号  peerName
    NSDate *senddate=[NSDate date];
    start = fStart;
    DLog(@"start:%f",start);
    //时间格式s
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
    NSString *  morelocationString=[dateformatter stringFromDate:senddate];
    
    //保存文件路径
    NSDateFormatter  *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *filePath = [NSString stringWithFormat:@"%@.mp4",[fileformatter stringFromDate:senddate]];
    
    sprintf(cRecordPath,"%s",cPath);
    sprintf(cDevName,"%s",cRecordDevName);
    //创建一个目录
    strDir = [kLibraryPath  stringByAppendingPathComponent:@"record"];
    BOOL bFlag = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:strDir isDirectory:&bFlag])
    {
        DLog(@"目录不存在");
        [[NSFileManager defaultManager] createDirectoryAtPath:strDir withIntermediateDirectories:NO attributes:nil error:nil];
        BOOL success = [[NSURL fileURLWithPath:strDir] setResourceValue: [NSNumber numberWithBool: YES]
                                                                 forKey: NSURLIsExcludedFromBackupKey error:nil];
        if(!success)
        {
            DLog(@"Error excluding不备份文件夹");
        }
    }
    //视频文件保存路径
    strFile  = [strDir stringByAppendingPathComponent:filePath];
    //开始时间与文件名
    sprintf(cStart, "%s",[morelocationString UTF8String]);
    sprintf(cFileName,"%s",[filePath UTF8String]);
    if ([[NSFileManager defaultManager] createFileAtPath:strFile contents:nil attributes:nil])
    {
        DLog(@"创建文件成功:%@",strFile);
    }
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:strFile];
    data = [[NSMutableData alloc] init];
    bFirst = NO;
    bRecord = YES;
    nFrameNum=0;
}
BOOL RecvFile::swichCode(int nType)
{
    //先清空之前的码流
    @synchronized(aryVideo)
    {
        [aryVideo removeAllObjects];
    }
    int nRet = -1;
    DLog(@"通道:%d-目标码流:%d",nChannel,nType);
    if (conn)
    {
        conn->StopRealStream(nChannel, nCode);
        [NSThread sleepForTimeInterval:3.0];
        if(conn)
        {
            DLog(@"conn 切换");
            nRet = conn->StartRealStream(nChannel, nType);//0 -1
            nCode = nType;
        }
        else
        {
            nRet = -1;
            DLog(@"切换失败");
        }
    }
    else if(relayconn)
    {
        relayconn->StopRealStream(nChannel, nCode);
        [NSThread sleepForTimeInterval:2.0];
        nRet = relayconn->StartRealStream(nChannel, nType);
        nCode = nType;
    }
    DLog(@"nRet:%d",nRet);//0是切换成功    
    if (!nRet)
    {
        return YES;
    }
    return NO;
}
int RecvFile::getRealType()
{
    if(conn)
    {
        return 1;
    }
    else
    {
        return 2;
    }
}
void RecvFile::sendPtzControl(PtzControlMsg *ptzMsg)
{
    if(conn)
    {
        conn->PtzContol(ptzMsg);
    }
    else
    {
        if(relayconn)
        {
            relayconn->PtzContol(ptzMsg);
        }
    }
}




