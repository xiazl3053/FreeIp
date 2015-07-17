//
//  P2PSDK_New.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/27.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "P2PSDK_New.h"

#import "RecordModel.h"
#import "RecordDb.h"
#import "XCNotification.h"

bool P2PSDK_New::ProcessFrameData(char* aFrameData, int aFrameDataLength)
{
    NSData *dataInfo = [NSData dataWithBytes:aFrameData length:aFrameDataLength];
    unsigned char *pbuf = (unsigned char*)aFrameData;
    if( pbuf[4]==0x61 && nNumberCatch == 2 )
    {
        nNumberCatch =(nNumberCatch == 1 ? 1 : 2);
        return YES;
    }
    @synchronized(aryVideo)
    {
        [aryVideo addObject:dataInfo];
    }
    dataInfo = nil;
//    DLog(@"%hhu--%hhu--%hhu--%hhu--%hhu",pbuf[0],pbuf[1],pbuf[2],pbuf[3],pbuf[4]);
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

    return YES;
}

void P2PSDK_New::clearVideoInfo()
{
    @synchronized(aryVideo)
    {
        [aryVideo removeAllObjects];
    }
}

BOOL P2PSDK_New::initP2PServer()
{
    if(conn == NULL)
    {
        conn = new Connection(this);
    }
    if (mSdk)
    {
        if(mSdk->Connect((char*)peerName.c_str(),conn)==0)
        {
            DLog(@"P2P连接设备成功");
            return YES;
        }
        DLog(@"P2P连接设备失败");
    }
    delete conn;
    conn = NULL;
    return NO;
}

BOOL P2PSDK_New::initTranServer()
{
    if (mSdk)
    {
        mSdk->SendHeartBeat();
    }
    if(relayconn == NULL)
    {
        relayconn = new RelayConnection(this);
        int ret = mSdk->RelayConnect((char*)peerName.c_str(),relayconn);
        if (ret==0)
        {
            DLog(@"中转成功");
            return YES;
        }
    }
    DLog(@"中转失败");
    delete relayconn;
    relayconn = NULL;
    return NO;
}

void P2PSDK_New::StopRecv()
{
    DLog(@"结束");
    if (conn)
    {
        conn->Close();
        delete conn;
        conn = NULL;
    }
    if(relayconn)
    {
        relayconn->Close();
        delete relayconn;
        relayconn = NULL;
    }
}

int P2PSDK_New::P2P_GetDeviceRecordInfo(struct _playrecordmsg*   recordsearch_req,struct  _playrecordresp*  recordsearch_resp)
{
    int ret=-1;
    if(conn != NULL)
    {
        ret = conn->GetDeviceRecordInfo(recordsearch_req,recordsearch_resp);
        if(ret == 0)//获取录像信息成功
        {
            printf("success P2P_GetDeviceRecordInfo \n");
        }
        else
        {
            printf("P2P_GetDeviceRecordInfo failed \n");
        }
    }
    return ret;
}

int P2PSDK_New::RELAY_GetDeviceRecordInfo(struct _playrecordmsg*   recordsearch_req,struct  _playrecordresp*  recordsearch_resp)
{
    int ret=-1;
//    relaymutex.lock();
    if(relayconn != NULL)
    {
        ret = relayconn->GetDeviceRecordInfo(recordsearch_req,recordsearch_resp);
        if(ret == 0)      //获取录像信息成功
        {
            printf("success RELAY_GetDeviceRecordInfo \n");
        }
        else
        {
            printf("RELAY_GetDeviceRecordInfo failed \n");
        }
    }
//    relaymutex.unlock();
    return ret;
}

int P2PSDK_New::TRAN_RecordSerach(struct _playrecordmsg*   recordsearch_req,char*  resp)
{
    printf("RecordSearch \n");
    int  result=-1;
    struct  _playrecordresp*  recordsearch_resp=NULL;
    struct  _playrecordmsg*    recordmsg=NULL;
    recordsearch_req->channelNo = nChannel;
    recordsearch_resp = (struct  _playrecordresp*)resp;
    recordmsg = (struct  _playrecordmsg*)(resp+sizeof(recordsearch_resp->count));
    if(relayconn)
    {
        result = RELAY_GetDeviceRecordInfo(recordsearch_req,recordsearch_resp);//中转方式获取录像相关信息
      	if(result<0)
        {
            DLog(@"tran get recordinfo failed!!!\n");    //获取设备录像信息失败
            return -1;
        }
        else     //获取设备录像信息成功
        {
            if(recordsearch_resp->count == 0)  //录像信息为空(可能无当天录像)
            {
                DLog(@"empty record!!!");
                return -2;
            }
            else
            {
                DLog(@"get recordinfo success!!!record count is %d\n",recordsearch_resp->count);
                return 0;
            }
        }
    }
    return -1;
}

int P2PSDK_New::P2P_RecordSearch(struct _playrecordmsg*   recordsearch_req,char*  resp)
{
    DLog(@"RecordSearch \n");
    int result=-1;
    struct  _playrecordresp*  recordsearch_resp=NULL;
    struct  _playrecordmsg*    recordmsg=NULL;
    recordsearch_req->channelNo = nChannel;
    recordsearch_resp = (struct  _playrecordresp*)resp;
    recordmsg = (struct  _playrecordmsg*)(resp+sizeof(recordsearch_resp->count));
    if(conn)
    {
        result = P2P_GetDeviceRecordInfo(recordsearch_req,recordsearch_resp);//P2P方式获取录像相关信息
        if(result<0)
        {
            DLog(@"get recordinfo failed!!!\n");//获取设备录像信息失败
            return -1;
        }
        else//获取设备录像信息成功
        {
            if(recordsearch_resp->count == 0)//录像信息为空(可能无当天录像)
            {
                printf("empty record!!!");
                return -2;
            }
            else
            {
                printf("get recordinfo success!!!record count is %d\n",recordsearch_resp->count);

                return 0;
            }
        }
    }
    return -1;
}

bool P2PSDK_New::DeviceDisconnectNotify()
{
    DLog(@"设备丢失了");
    [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DISCONNECT object:nil];
    return YES;
}
long p2pGetTime(RecordTime time)
{
    NSDateFormatter* fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    //1436500800
    NSString *strTime = [NSString stringWithFormat:@"%d-%02d-%02d %02d:%02d:%02d",
                         time.myear,time.mmonth,time.mday,time.mhour,time.mminute,time.msec];
    NSDate *testTime = [fmt dateFromString:strTime];
    
    NSTimeInterval timeInfo = [testTime timeIntervalSince1970];
    return timeInfo;
}
bool P2PSDK_New::RecordEndNotify(char* aNotifyData, int aNotifyDataLength)
{
    DLog(@"1234567890:%s",aNotifyData);
    if (aNotifyDataLength < sizeof(RecordEndNotifyMsg)) {
        DLog(@"结构体长度错误");
        return NO;
    }
    RecordEndNotifyMsg *msg = (RecordEndNotifyMsg*)aNotifyData;
    
    printf("channel is %d,starttime is %d-%d-%d %d:%d:%d,endtime is %d-%d-%d %d:%d:%d\n",msg->channelNo,
           msg->startTime.myear,msg->startTime.mmonth,msg->startTime.mday,msg->startTime.mhour,msg->startTime.mminute,
           msg->startTime.msec,msg->endTime.myear,msg->endTime.mmonth,msg->endTime.mday,msg->endTime.mhour,msg->endTime.mminute,msg->endTime.msec
           );
    NSString *strTime = [NSString stringWithFormat:@"%d-%02d-%02d %02d:%02d:%02d",
                         msg->startTime.myear,msg->startTime.mmonth,msg->startTime.mday,msg->startTime.mhour,msg->startTime.mminute,
                         msg->startTime.msec];
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_REMOTE_FILE_END_VC object:strTime];
 
    
    return false;
}

int P2PSDK_New::P2P_PlayDeviceRecord(struct _playrecordmsg*   playrecord_req)
{
    int ret=-1;
    if(conn != NULL)
    {
        ret = conn->PlayBackRecord(playrecord_req);
        if(ret == 0)    //请求P2P录像流成功
        {
            aryVideo = [NSMutableArray array];
            printf("success P2P_PlayDeviceRecord \n");
        }
        else
        {
            printf("P2P_PlayDeviceRecord failed \n");
        }
    }
    return ret;
}

int P2PSDK_New::RELAY_PlayDeviceRecord(struct _playrecordmsg*   playrecord_req)
{
    int ret=-1;
    if(relayconn != NULL)
    {
        ret = relayconn->PlayBackRecord(playrecord_req);
        if(ret == 0)    //请求中转录像流成功
        {
            aryVideo = [NSMutableArray array];
            printf("success RELAY_PlayDeviceRecord \n");
        }
        else
        {
            printf("RELAY_PlayDeviceRecord failed \n");
        }
    }
    return ret;
}

int P2PSDK_New::closeTranServer()
{
    if (relayconn)
    {
        relayconn->Close();
        delete relayconn;
        relayconn = NULL;
    }
    return 1;
}

int P2PSDK_New::closeP2PService()
{
    if (conn)
    {
        conn->Close();
        
        delete conn;
        conn = NULL;
    }
    return 1;
}

int P2PSDK_New::stopDeviceRecord(struct _playrecordmsg* playrecord_req)
{
    if (conn)
    {
        conn->StopBackRecord(playrecord_req);
    }
    else
    {
        relayconn->StopBackRecord(playrecord_req);
    }
    @synchronized(aryVideo)
    {
        [aryVideo removeAllObjects];
    }
    return 1;
}

int P2PSDK_New::controlDeviceRecord(PlayRecordCtrlMsg *control)
{
    if (conn)
    {
        conn->PlayBackRecordCtrl(control);
    }
    else if(relayconn)
    {
        relayconn->PlayBackRecordCtrl(control);
    }
    return 1;
}

int P2PSDK_New::P2P_RecordDrag(RecordDragMsg* recorddragmsg)
{
    int ret=-1;

    if(conn != NULL)
    {
        ret = conn->DragRecordStream(recorddragmsg);
        if(ret == 0)
        {
            printf("success P2P_RecordDrag \n");
        }
        else
        {
            printf("P2P_RecordDrag failed \n");
        }
    }

    return ret;
}
int P2PSDK_New::RELAY_RecordDrag(RecordDragMsg* recorddragmsg)
{
    int ret=-1;

    if(relayconn != NULL)
    {
        ret = relayconn->DragRecordStream(recorddragmsg);
        if(ret == 0)
        {
            printf("success RELAY_RecordDrag \n");
        }
        else
        {
            printf("RELAY_RecordDrag failed \n");
        }
    }
    return ret;
}

void P2PSDK_New::startRecord(const char * cPath,const char *cRecordDevName)
{
    NSDate *senddate=[NSDate date];
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

void P2PSDK_New::stopRecord(int nBit)
{
    if (!bRecord)
    {
        return ;
    }
    bRecord = NO;
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
    DLog(@"帧数:%d",nFrameNum);
    record.nFramesNum = nFrameNum;
    record.nFrameBit = nBit;
    [RecordDb insertRecord:record];
    data = nil;
}