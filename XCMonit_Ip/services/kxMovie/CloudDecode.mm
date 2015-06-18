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
#import "DecoderPublic.h"

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
@end



@implementation CloudDecode

-(id)initWithCloud:(NSString*)strNo channel:(int)nChannel codeType:(int)nCode
{
    self = [super init];
    connectStatus = 0;
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
    dispatch_async(dispatch_get_global_queue(0, 0),^{
        [__self startInitSdk];
    });
}

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
    struct _playrecordmsg recordreq;
    char responsedata[MAX_MSG_DATA_LEN];
    recordreq.channelNo = 1;
    recordreq.frameType = 0;
    NSDateFormatter* fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *testTime = [fmt dateFromString:_strTime];

    int time = abs((int)[testTime timeIntervalSinceNow]);
    recordreq.startTime = time;
    recordreq.endTime = time+86400;
    recordreq.nalarmFileType = 1;
    if(bPTP)
    {
        sdkNew->P2P_RecordSearch(&recordreq,responsedata);
    }
    else if(bTran)
    {
        sdkNew->TRAN_RecordSerach(&recordreq,responsedata);
        memcpy(&_recordreq,responsedata+4,sizeof(struct _playrecordmsg));
        DLog(@"%d--%d--%u--%u",_recordreq.frameType,_recordreq.channelNo,_recordreq.startTime,_recordreq.endTime);
    }
}

-(void)thread_p2p
{
    BOOL bFlag = sdkNew->initP2PServer();
    if (bFlag)
    {
        bPTP = YES;
        bTran = NO;
        connectStatus = 1;
    }
}

-(void)thread_tran
{
    BOOL bFlag = sdkNew->initTranServer();
    if (bFlag)
    {
        DLog(@"中转成功!!!!");
        if (bPTP)
        {
            bTran = NO;
        }
        bTran = YES;
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

-(BOOL)startVideo:(NSString *)strTime
{
    theLock = [[NSRecursiveLock alloc] init];
    bStop = YES;
    if (bTran)
    {
        DLog(@"%d--%d--%u--%u",_recordreq.frameType,_recordreq.channelNo,_recordreq.startTime,_recordreq.endTime);
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
    uint8_t *puf = nil;
    while (!bFinish)
    {
        nRef = 0;
        @synchronized(sdkNew->aryVideo)
        {
            if (sdkNew->aryVideo.count>0)
            {
                NSData *data = [sdkNew->aryVideo objectAtIndex:0];
                puf = (uint8_t *)malloc([data length]);
                packet.size = (int)data.length;
                memcpy(puf, [data bytes], data.length);
                [sdkNew->aryVideo removeObjectAtIndex:0];
                data = nil;
                packet.data = puf;
            }
            else
            {
                packet.size = 0;
            }
        }
        if (packet.size==0)
        {
            [NSThread sleepForTimeInterval:0.03f];
            continue;
        }
        if(nRef>=0 && bStop)
        {
            [theLock lock];
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
                [theLock unlock];
                continue;
            }
            [theLock unlock];
        }
        else
        {
            break;
        }
    }
    av_free_packet(&packet);
    free(puf);
    return result;
}

#pragma mark yuv 转换
- (KxVideoFrame *) handleVideoFrame
{
    if (!pVideoFrame->data[0])
        return nil;
    
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
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        return NO;
    }
    pVideoFrame = avcodec_alloc_frame();
    pNewVideoFrame = avcodec_alloc_frame();
    if( pVideoFrame == NULL )
    {
        return NO;
    }
    _fps = 30;
    DLog(@"fps:%f",_fps);
    
    return YES;
}

-(void)stopDecode
{
    sdkNew->stopDeviceRecord(&_recordreq);
    bStop = NO;
    [self closeScaler];
    [self closeFile];
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
    if (sdkNew) {
        sdkNew->StopRecv();
        delete sdkNew;
        sdkNew = NULL;
    }
}

@end
