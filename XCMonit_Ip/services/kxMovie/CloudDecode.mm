//
//  CloudDecode.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/27.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "CloudDecode.h"
#import "P2PSDK_New.h"
#import "NSDate+convenience.h"
#import "P2PInitService.h"
#import "DecoderPublic.h"
#import "TimeView.h"
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
    BOOL bPTP;
    BOOL bTran;
    int connectStatus;
    
    //ffmpeg
    AVFormatContext     *pFormatCtx;
    AVCodecContext      *pCodecCtx;
    AVFrame             *pVideoFrame;
    AVFrame             *pNewVideoFrame;
    struct SwsContext   *_swsContext;
    AVPicture           _picture;
    BOOL _pictureValid;
    struct _playrecordmsg _recordreq;
    BOOL bStop;
    NSRecursiveLock *theLock;
    
    
}

@property (nonatomic,strong) NSMutableArray *aryDateInfo;



@end

@implementation CloudDecode

-(id)initWithCloud:(NSString*)strNo channel:(int)nChannel codeType:(int)nCode
{
    self = [super init];
    connectStatus = 0;
    _nChannel = nChannel;
    DLog(@"nChannel:%d",nChannel);
    _strNO = strNo;
    nStreamType = nCode;
    memset(&_recordreq, 0, sizeof(struct _playrecordmsg));
    __weak CloudDecode *__self = self;
    _aryDateInfo = [NSMutableArray array];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [__self newSdkInfo];
    });
    return self;
}

#pragma mark 创建p2p、tran对象
-(void)newSdkInfo
{
    P2PSDKClient *sdk = [[P2PInitService sharedP2PInitService] getP2PSDK];
    if(!sdk)
    {
        DLog(@"初始化失败");
        connectStatus = -1;
        return ;
    }
    sdkNew = new P2PSDK_New(sdk,0,_nChannel);
    sdkNew->peerName = [_strNO UTF8String];
    __weak CloudDecode *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__self startInitSdk];
    });
}

#pragma mark 云存储查询
-(void)checkView:(NSString *)strTime
{
    _strTime = [strTime copy];
    CGFloat fTime = 0;
    while (connectStatus==0)
    {
        [NSThread sleepForTimeInterval:0.1f];
        fTime += 0.1;
        if (fTime >= 30)
        {
            return ;
        }
    }
    if (connectStatus==-1)
    {
        if (_cloudBlock)
        {
            _cloudBlock(-1,nil);
        }
        return;
    }
    //请求录像记录
    struct _playrecordmsg recordreq;
    char responsedata[MAX_MSG_DATA_LEN];
    recordreq.channelNo = _nChannel;
    recordreq.frameType = 0;
    NSDateFormatter* fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    NSDate *testTime = [fmt dateFromString:_strTime];
    recordreq.startTime.myear = testTime.year;
    recordreq.startTime.mmonth = testTime.month;
    recordreq.startTime.mday = testTime.day;
    recordreq.startTime.mhour = 0;
    recordreq.startTime.mminute = 0;
    recordreq.startTime.msec = 0;
    
    DLog(@"time:%@",testTime);
    
    size_t size_msg = sizeof(struct _playrecordmsg);
    recordreq.endTime.myear = testTime.year;
    recordreq.endTime.mmonth = testTime.month;
    recordreq.endTime.mday = testTime.day;
    recordreq.endTime.mhour = 23;
    recordreq.endTime.mminute = 59;
    recordreq.endTime.msec = 59;
    recordreq.nrecordFileType = 1;
   if(bPTP)
    {
        int nRef = sdkNew->P2P_RecordSearch(&recordreq,responsedata);
        if (nRef!=0)
        {
            if (_cloudBlock)
            {
                _cloudBlock(0,nil);
            }
            return ;
        }
        int nCount;
        memcpy((char*)&nCount,responsedata,4);
        DLog(@"nCout:%d",nCount);
        if (nCount>0)
        {
            struct _playrecordmsg recordMsg;
            NSMutableArray *aryItem = [NSMutableArray array];
            for (int i=0; i<nCount; i++)
            {
                memcpy(&recordMsg,responsedata+4+i*size_msg,size_msg);
                CloudTime *time = [[CloudTime alloc] init];
                
                time.iStart = [self getTime:recordMsg.startTime];
                time.iEnd = [self getTime:recordMsg.endTime];
                
                DLog(@"start:%d---end:%d",time.iStart,time.iEnd);
                [aryItem addObject:time];
            }
            if(_cloudBlock)
            {
                [_aryDateInfo removeAllObjects];
                [_aryDateInfo addObjectsFromArray:aryItem];
                _cloudBlock(nCount,aryItem);
            }
        }
        else
        {
            if(_cloudBlock)
            {
                _cloudBlock(0,nil);
            }
        }
    }
    else if(bTran)
    {
        int nRef = sdkNew->TRAN_RecordSerach(&recordreq,responsedata);
        if (nRef!=0) {
            if (_cloudBlock)
            {
                _cloudBlock(0,nil);
            }
            return ;
        }
        memcpy(&_recordreq,responsedata+4,sizeof(struct _playrecordmsg));
        int nCount;
        memcpy((char*)&nCount,responsedata,4);
        if (nCount>0)
        {
            struct _playrecordmsg recordMsg;
            NSMutableArray *aryItem = [NSMutableArray array];
            for (int i=0; i<nCount; i++)
            {
                memcpy(&recordMsg,responsedata+4+i*size_msg,size_msg);
                CloudTime *time = [[CloudTime alloc] init];
                time.iStart = [self getTime:recordMsg.startTime];
                time.iEnd = [self getTime:recordMsg.endTime];
                [aryItem addObject:time];
            }
            if(_cloudBlock)
            {
                [_aryDateInfo removeAllObjects];
                [_aryDateInfo addObjectsFromArray:aryItem];
                _cloudBlock(nCount,aryItem);
            }
        }
        else
        {
            DLog(@"error count");
        }
    } 
}

-(void)thread_p2p
{
    BOOL bFlag = sdkNew->initP2PServer();
    if (bFlag)
    {
        bPTP = YES;
        if(bTran==YES)
        {
            if (_recordreq.startTime.myear!=0)
            {
                sdkNew->stopDeviceRecord(&_recordreq);
                sdkNew->P2P_PlayDeviceRecord(&_recordreq);
            }
            bTran = NO;
        }
        connectStatus = 1;
    }
}

-(void)thread_tran
{
    BOOL bFlag = sdkNew->initTranServer();
    if (bFlag)
    {
        if (bPTP)
        {
            sdkNew->closeTranServer();
            bTran = NO;
        }
        else
        {
            bTran = YES;
        }
        connectStatus = 1;
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


-(BOOL)startVideo:(long)lTime
{
    theLock = [[NSRecursiveLock alloc] init];
    _recordreq.channelNo = _nChannel;
    struct tm *m_start = localtime(&lTime);
    if(_aryDateInfo.count==0)
    {
        return NO;
    }
    _recordreq.startTime.myear = m_start->tm_year+1900;
    _recordreq.startTime.mmonth = m_start->tm_mon+1;
    _recordreq.startTime.mday = m_start->tm_mday;
    _recordreq.startTime.mhour = m_start->tm_hour;
    _recordreq.startTime.mminute = m_start->tm_min;
    _recordreq.startTime.msec = m_start->tm_sec;
    CloudTime *cloud = [_aryDateInfo objectAtIndex:_aryDateInfo.count - 1];
   
    long lEnd = cloud.iEnd;
    struct tm *m_end = localtime(&lEnd);
    _recordreq.endTime.myear = m_end->tm_year+1900;
    _recordreq.endTime.mmonth = m_end->tm_mon+1;
    _recordreq.endTime.mday = m_end->tm_mday;
    _recordreq.endTime.mhour = m_end->tm_hour;
    _recordreq.endTime.mminute = m_end->tm_min;
    _recordreq.endTime.msec = m_end->tm_sec;
    _recordreq.nrecordFileType = 1;
    _recordreq.frameType = nStreamType;
    if (bTran)
    {
        _recordreq.channelNo = _nChannel;
        DLog(@"_recordreq.chh:%d",_recordreq.channelNo);
        DLog(@"%d--%d--%u--%u",_recordreq.frameType,_recordreq.channelNo,_recordreq.startTime.mhour,_recordreq.endTime.mhour);
        if(sdkNew->RELAY_PlayDeviceRecord(&_recordreq)==0)
        {
            __weak CloudDecode *__self = self;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [__self ffmpegInit];
            });
            return YES;
        }
        DLog(@"TRAN网络超时");
    }
    else if(bPTP)
    {
        _recordreq.channelNo = _nChannel;
        DLog(@"%d--%d--%u--%u",_recordreq.frameType,_recordreq.channelNo,_recordreq.startTime.mhour,_recordreq.endTime.mhour);
        if(sdkNew->P2P_PlayDeviceRecord(&_recordreq)==0)
        {
            __weak CloudDecode *__self = self;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [__self ffmpegInit];
            });
            return YES;
        }
        DLog(@"P2P网络超时");
    }
    return NO;
}

-(void)startInitSdk
{
    __weak CloudDecode *__self = self;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(0,0),
    ^{
        [__self thread_p2p];
        [__self thread_tran];
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    if (!bTran && !bPTP)
    {
        DLog(@"都失败了");
        connectStatus = -1;
    }
}

-(NSArray*)decodeFrame
{
    int gotframe;
    AVPacket packet;
    av_init_packet(&packet);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL bFinish = NO;
    int nRef = 0;
    while (!bFinish)
    {
        nRef = 0;
        NSData *data = nil;
        @synchronized(sdkNew->aryVideo)
        {
            if (sdkNew->aryVideo.count>0)
            {
                data = [sdkNew->aryVideo objectAtIndex:0];
                packet.size = (int)data.length;
                [sdkNew->aryVideo removeObjectAtIndex:0];
                packet.data = (uint8_t*)[data bytes];
            }
            else
            {
                packet.size = 0;
            }
        }
        if (packet.size==0)
        {
            [NSThread sleepForTimeInterval:0.001];
            continue;
        }
        [theLock lock];
        if(nRef>=0 && bStop)
        {
            int len = avcodec_decode_video2(pCodecCtx,pVideoFrame,&gotframe,&packet);
            if (gotframe)
            {
                KxVideoFrame *frameVideo = [self handleVideoFrame];
                if (frameVideo)
                {
                    [result addObject:frameVideo];
                    bFinish = YES;
                }
                frameVideo = nil;
            }
            if (0 == len || -1 == len)
            {
                data = nil;
                [theLock unlock];
                continue;
            }
        }
        else
        {
            
            data = nil;
            [theLock unlock];
            break;
        }
        data = nil;
        [theLock unlock];
    }
    av_free_packet(&packet);
    return result;
}

#pragma mark yuv 转换
- (KxVideoFrame *) handleVideoFrame
{
       if (!pVideoFrame || !pVideoFrame->data[0])
       {
           return nil;
       }
       KxVideoFrame *frame;
        if (!_swsContext && ![self setupScaler])
        {
            DLog(@"fail setup video scaler");
            return nil;
        }
        sws_scale(_swsContext,
                  (const uint8_t **)pVideoFrame->data,
                  pVideoFrame->linesize,
                  0,
                  pCodecCtx->height,
                  _picture.data,
                  _picture.linesize);
        KxVideoFrameRGB *rgbFrame = [[KxVideoFrameRGB alloc] init];
        rgbFrame.linesize = _picture.linesize[0];
        rgbFrame.rgb = [NSData dataWithBytes:_picture.data[0]
                                      length:rgbFrame.linesize * pCodecCtx->height];
    frame = rgbFrame;
    frame.width = pCodecCtx->width;
    frame.height = pCodecCtx->height;
    frame.duration = 1.0 / _fps;
    
    return frame;
}

#pragma mark rgb
- (BOOL) setupScaler
{
    [self closeScaler];
    DLog(@"新的:%d-%d",pCodecCtx->width,pCodecCtx->height);
    _pictureValid = avpicture_alloc(&_picture,
                                    PIX_FMT_RGB24,
                                    pCodecCtx->width,
                                    pCodecCtx->height) == 0;
    if (!_pictureValid)
        return NO;
    _swsContext = sws_getCachedContext(_swsContext,
                                       pCodecCtx->width,
                                       pCodecCtx->height,
                                       pCodecCtx->pix_fmt,
                                       pCodecCtx->width,
                                       pCodecCtx->height,
                                       PIX_FMT_RGB24,
                                       SWS_FAST_BILINEAR,
                                       NULL, NULL, NULL);
    
    return _swsContext != NULL;
}

#pragma mark 关闭转换
- (void) closeScaler
{
    if (_swsContext) {
        sws_freeContext(_swsContext);
        _swsContext = NULL;
    }
    
    if (_pictureValid)
    {
        avpicture_free(&_picture);
        _pictureValid = NO;
    }
}

-(BOOL)ffmpegInit
{
    pFormatCtx = NULL;
    pFormatCtx = avformat_alloc_context();
    AVCodec         *pCodec = NULL;
    pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    pCodecCtx = avcodec_alloc_context3(pCodec);
    
    [[[P2PInitService sharedP2PInitService] getTheLock] lock];
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        
        [[[P2PInitService sharedP2PInitService] getTheLock] unlock];
        return NO;
    }
    [[[P2PInitService sharedP2PInitService] getTheLock] unlock];
    pVideoFrame = avcodec_alloc_frame();
    pNewVideoFrame = avcodec_alloc_frame();
    if( pVideoFrame == NULL )
    {
        return NO;
    }
    _fps = 30;
    DLog(@"fps:%f",_fps);
    bStop = YES;
    return YES;
}

-(void)stopDecode
{
    [theLock lock];
    if(_recordreq.startTime.mminute!=0)
    {
        sdkNew->stopDeviceRecord(&_recordreq);
    }
    memset(&_recordreq, 0, sizeof(struct _playrecordmsg));
    bStop = NO;
    [self closeScaler];
    [self closeFile];
    DLog(@"停止");
    [theLock unlock];
}

-(void)closeFile
{
    
    if (pVideoFrame)
    {
        av_free(pVideoFrame);
        pVideoFrame = NULL;
    }
    if (pCodecCtx)
    {
        [[[P2PInitService sharedP2PInitService] getTheLock] lock];
        avcodec_close(pCodecCtx);
        [[[P2PInitService sharedP2PInitService] getTheLock] unlock];
        pCodecCtx = NULL;
    }
    if (pFormatCtx)
    {
        pFormatCtx->interrupt_callback.opaque = NULL;
        pFormatCtx->interrupt_callback.callback = NULL;
        avformat_close_input(&pFormatCtx);
        pFormatCtx = NULL;
    }
}

-(void)regainVideo
{
    PlayRecordCtrlMsg backControl;
    backControl.channelNo = _nChannel;
    backControl.frameType = 1;
    backControl.ctrl = PB_PLAY;
    sdkNew->controlDeviceRecord(&backControl);   
}

-(void)pauseVideo
{
    PlayRecordCtrlMsg backControl;
    backControl.channelNo = _nChannel;
    backControl.frameType = 1;
    backControl.ctrl = PB_PAUSE;
    sdkNew->controlDeviceRecord(&backControl);
}

-(void)dealloc
{
    if (sdkNew)
    {
        sdkNew->StopRecv();
        delete sdkNew;
        sdkNew = NULL;
    }
    [self closeFile];
    DLog(@"stop");
}


-(void)dragTime:(long)lTime
{
    DLog(@"时间移动");
    CloudTime *cloud = [_aryDateInfo objectAtIndex:_aryDateInfo.count - 1];
    RecordDragMsg recordDrag;
    memset(&recordDrag, 0, sizeof(RecordDragMsg));
    struct tm *m_start = localtime(&lTime);
    recordDrag.channelNo = _nChannel;
    recordDrag.startTime.myear = m_start->tm_year+1900;
    recordDrag.startTime.mmonth = m_start->tm_mon+1;
    recordDrag.startTime.mday = m_start->tm_mday;
    recordDrag.startTime.mhour = m_start->tm_hour;
    recordDrag.startTime.mminute = m_start->tm_min;
    recordDrag.startTime.msec = m_start->tm_sec;
    
    long lEnd = cloud.iEnd;
    struct tm *tm_end = localtime(&lEnd);
    recordDrag.endTime.myear = tm_end->tm_year+1900;
    recordDrag.endTime.mmonth = tm_end->tm_mon+1;
    recordDrag.endTime.mday = tm_end->tm_mday;
    recordDrag.endTime.mhour = tm_end->tm_hour;
    recordDrag.endTime.mminute = tm_end->tm_min;
    recordDrag.endTime.msec = tm_end->tm_sec;
    recordDrag.recordvideoType = _recordreq.nrecordFileType;
    if (bPTP)
    {
        if (sdkNew)
        {
            sdkNew->P2P_RecordDrag(&recordDrag);
        }
    }
    else if(bTran)
    {
        if (sdkNew)
        {
            sdkNew->RELAY_RecordDrag(&recordDrag);
        }       
    }
    else
    {
        
    }
    sdkNew->clearVideoInfo();
}

-(NSTimeInterval)getTime:(RecordTime)time
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

-(void)startRecord:(NSString *)strPath devName:(NSString *)strDevName
{
    if (sdkNew)
    {
        sdkNew->startRecord([strPath UTF8String], [strDevName UTF8String]);
    }
}

-(void)stopRecord
{
    if (sdkNew)
    {
        sdkNew->stopRecord(25);
    }
}


@end
