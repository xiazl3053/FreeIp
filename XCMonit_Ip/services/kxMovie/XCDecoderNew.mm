//
//  XCDecoderNew.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "XCDecoderNew.h"
#import "P2PInitService.h"
#import "P2PSDKClient.h"
#import "P2PSDKService.h"
#import "XCNotification.h"
#include <sys/time.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>

#define PPSHAREINIT [P2PInitService sharedP2PInitService]

#define kMaxBufferDuration_DVR   0.02
#define kMinBufferDuration_DVR   0.01
extern "C"
{
    #include "libavformat/avformat.h"
    #include "libswscale/swscale.h"
}


int read_code(void *opaque, uint8_t *buf, int buf_size)
{
    int size = buf_size;

    int ret = -1;
    struct timeval tv;
    gettimeofday(&tv,NULL);
    RecvFile *recvInfo = (RecvFile *)opaque;
    do
    {
        if(!recvInfo || recvInfo->bExit)
        {
            return -1;
        }
        struct timeval result;
        gettimeofday(&result,NULL);
        @synchronized(recvInfo->aryVideo)
        {
            if (recvInfo->aryVideo.count>0)
            {
                NSData *data = [recvInfo->aryVideo objectAtIndex:0];
                size = (int)data.length;
                memcpy(buf, [data bytes], data.length);
                [recvInfo->aryVideo removeObjectAtIndex:0];
                ret = 0;
            }
        }
        if(result.tv_sec-tv.tv_sec>=30)
        {
            DLog(@"退出了");
            return -1;
        }
    }while(ret);
    return size;
}

NSData* copyFrameDataNew(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength:width * height]; //[NSMutableData dataWithLength: width * height];
    Byte *dst = (Byte *)md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i)
    {
        if(dst)
        {
            memcpy(dst, src, width);
            dst += width;
            src += linesize;
        }
    }
    return md;
}



@interface XCDecoderNew()
{
    dispatch_queue_t _dispatch_queue;
    
    RecvFile *recv;//P2P连接操作
    P2PSDKClient *sdk;//SDK对象
    KxVideoFrameFormat  _videoFrameFormat;//解码贴图
    pthread_mutex_t mutex;
    //FFMPEG对象
    AVFormatContext     *pFormatCtx;
    AVCodecContext      *pSubtitleCodecCtx;
    AVCodecContext      *pAudioCodecCtx;
    AVCodecContext      *pCodecCtx;
    struct  SwsContext   *_swsContext;
    AVPicture           _picture;
    BOOL                _pictureValid;
    
    int                 nConnectStatus;
    int                 nFormat;
    int                 _videoStream;
    //
    AVFrame            *pVideoFrame;
    CGFloat fSrcWidth,fSrcHeight;
    BOOL               _bIsDecoding;
    BOOL               bFirst;
    CGFloat            _videoTimeBase;
    bool               _destorySDK;
    BOOL               _isEOF;
    NSUInteger    _tickCounter;
    int nFFMpegStatus;
    
    float _bufferedDuration;
    CGFloat _minBufferedDuration;
    CGFloat _maxBufferedDuration;
    CGFloat _moviePosition;
    NSInteger nStartNum;
}
@property (nonatomic,assign) BOOL     decoding;
@property (nonatomic,assign) BOOL   bP2P;
@property (nonatomic,assign) BOOL bTran;
@property (nonatomic,assign) NSInteger nNum;
//@property (nonatomic,assign) int nChannel;

@end

@implementation XCDecoderNew

-(id)init
{
    self = [super init];
    _bNotify = YES;
    nFormat = 1;
    _destorySDK = NO;
    nFFMpegStatus = 0;
    return self;
}

-(id)initWithFormat:(KxVideoFrameFormat)format codeType:(int)nCodeType
{
    self = [super init];
    _bNotify = YES;
    nFormat = 1;
    _nCodeType = nCodeType;
    DLog(@"请求类型:%d",_nCodeType);
    nFFMpegStatus = 0;
    _videoFrameFormat = format;
    return self;
}

-(void)startConnect:(NSString *)strNo
{
    __weak XCDecoderNew *weakSelf = self;
    _strNO = strNo;

    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [weakSelf startP2PServer:weakSelf.strNO];
        [weakSelf initVideoParam];
    });
}

-(void)startConnectWithChan:(NSString *)strNo channel:(int)nChannel
{
    _nChannel = nChannel;
    _strNO = strNo;
    __weak XCDecoderNew *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
       [weakSelf startP2PServer:weakSelf.strNO];
       [weakSelf initVideoParam];
    });
}

-(void)stopVideo
{
    
}

#pragma mark 解码操作 P2P方式
-(BOOL)initVideoParam
{
    DLog(@"开始时间");
    while (YES)
    {
        if (nConnectStatus==1)
        {
            break;
        }
        else if(nConnectStatus == -1)
        {
            DLog(@"结束");
            return NO;
        }
        if (!_bNotify)
        {
            DLog(@"退出了?");
            return NO;
        }
        [NSThread sleepForTimeInterval:1.0f];
    }
    DLog(@"开始解码方法:%@",_strNO);
    nFFMpegStatus = 1;
    _videoArray = [NSMutableArray array];
    _bIsDecoding = NO;
    pFormatCtx = avformat_alloc_context();
    pFormatCtx->max_analyze_duration=100000;
    pFormatCtx->probesize = 100000;
    
    if(_videoStream == -1 )
    {
        DLog(@"找不到视频数据");
        return NO;
    }
    AVCodec *pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    pCodecCtx = avcodec_alloc_context3(pCodec);
    
    if(pCodec == nil)
    {
        DLog(@"跑了？");
        return NO;
    }
    DLog(@"找到码流");
    [[PPSHAREINIT getTheLock] lock];
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0 )
    {
        return NO;
    }
    [[PPSHAREINIT getTheLock] unlock];
    if(pCodec->capabilities&CODEC_CAP_TRUNCATED)
    {
        pCodecCtx->flags |= CODEC_FLAG_TRUNCATED;
    }
    pVideoFrame = avcodec_alloc_frame();
    if(pVideoFrame == NULL)
    {
        return NO;
    }
    _fFPS = 25.0f;
    _bIsDecoding = YES;
    nFFMpegStatus = 2;
    return YES;
    
Release_avformat_open_input:
    
    avformat_free_context(pFormatCtx);
    pFormatCtx = NULL;
    if (_bNotify)
    {
        self.nError = 2;
        self.strError = XCLocalized(@"nostream");
        [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:self];
    }
    return NO;
}

#pragma mark  play函数
-(void)startPlay
{
    DLog(@"开启播放");
    _decoding = NO;
    _playing = YES;
    __weak XCDecoderNew *__weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [__weakSelf tick];
    });
}
#pragma mark 持续解码
-(void)tick
{
    if(!_playing)
    {
        DLog(@"已经退出");
        [self closeScaler];
        [self closeFile];
        return;
    }
    const NSUInteger leftFrames = _videoArray.count;
    if (leftFrames==0)
    {
        [self asyncDecodeFrames];
    }
    const NSTimeInterval time = MAX(1.0/_fFPS*0.5, 0.025);// 1/25 * 0.25
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
    __weak XCDecoderNew *weakSelf = self;
    dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
    {
       [weakSelf tick];
    });
}

- (void)asyncDecodeFrames
{
    if (_decoding)
    {
        return;
    }
    _decoding = YES;
    if (!_playing)
    {
            return ;
    }
    BOOL good = YES;
    while (good && _playing)
    {
        good = NO;
        NSArray *frames = [self decodeFrames];
        if(frames.count>0)
        {
            good = [self addFrames:frames];
        }
        frames = nil;
    }
    if (!_playing)
    {
        DLog(@"已经中断");
    }
    _decoding = NO;

}
#pragma mark 添加frame
-(BOOL)addFrames:(NSArray*)frames
{
    @synchronized(_videoArray)
    {
        for (KxMovieFrame *frame in frames)
        {
            if (frame.type == KxMovieFrameTypeVideo)
            {
                [_videoArray addObject:frame];
                _bufferedDuration += frame.duration;
            }
        }
    }
    return _playing && _bufferedDuration < kMinBufferDuration_DVR;
}

-(KxVideoFrame*)getNextFrame
{
    KxVideoFrame *frame;
    @synchronized(_videoArray)
    {
        if (_videoArray.count > 0)
        {
            frame = _videoArray[0];
            [_videoArray removeObjectAtIndex:0];
        }
    }
    if (frame)
    {
        _bufferedDuration -= frame.duration;
    }
    else
    {
        return nil;
    }
    return frame;
}

-(NSMutableArray*)getVideoArray
{
    return _videoArray;
}

#pragma mark 解码
-(NSMutableArray*)decodeFrames
{
    int gotframe;
    AVPacket packet;
    av_init_packet(&packet);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL bFinish = NO;
    int nRef = 0;
    if (!_playing || !_bIsDecoding)
    {
        return  result;
    }
    uint8_t *puf = (uint8_t *)malloc(500*1024);
    while (!bFinish)
    {
        if (!_bNotify)
        {
            return result;
        }
        nRef = 0;
        @synchronized(recv->aryVideo)
        {
            if (recv->aryVideo.count>0)
            {
                NSData *data = [recv->aryVideo objectAtIndex:0];
                if(data.length<500*1024)
                {
                    packet.size = (int)data.length;
                    memcpy(puf, [data bytes], data.length);
                    [recv->aryVideo removeObjectAtIndex:0];
                    packet.data = puf;
                }
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
        if(nRef>=0)
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
            }
            if (0 == len || -1 == len)
            {
                break;
            }
        }
        else
        {
            //结束
            _isEOF = YES;
            _nError = 3;//Disconnect
            _strError = XCLocalized(@"Disconnect");
            DLog(@"_strError:%@",_strError);
            if (_bNotify)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:self];
                _bNotify = NO;
            }
            break;
        }
        av_free_packet(&packet);

    }
    free(puf);
    return result;
}

#pragma mark 处理yuv数据
-(KxVideoFrame *)handleVideoFrame
{
    if (!pVideoFrame->data[0])
        return nil;
    
    KxVideoFrame *frame;
    
    if (_videoFrameFormat == KxVideoFrameFormatYUV) {
        
        KxVideoFrameYUV * yuvFrame = [[KxVideoFrameYUV alloc] init];
        
        yuvFrame.luma = copyFrameDataNew(pVideoFrame->data[0],
                                      pVideoFrame->linesize[0],
                                      pVideoFrame->width,
                                      pVideoFrame->height);
        
        yuvFrame.chromaB = copyFrameDataNew(pVideoFrame->data[1],
                                         pVideoFrame->linesize[1],
                                         pVideoFrame->width / 2,
                                         pVideoFrame->height / 2);
        
        yuvFrame.chromaR = copyFrameDataNew(pVideoFrame->data[2],
                                         pVideoFrame->linesize[2],
                                         pVideoFrame->width / 2,
                                         pVideoFrame->height / 2);
        frame = yuvFrame;
        
    } else
    {
        if (fSrcWidth != pCodecCtx->width || fSrcHeight != pCodecCtx->height)
        {
            avcodec_flush_buffers(pCodecCtx);
            [self setupScaler];
            fSrcWidth = pCodecCtx->width;
            fSrcHeight = pCodecCtx->height;
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
    }

    frame.width = pCodecCtx->width;
    frame.height = pCodecCtx->height;
    frame.duration = 1.0 / _fFPS;
    _moviePosition += frame.duration;
    frame.position = _moviePosition;
    return frame;
}


#pragma mark  获取fps信息

-(void)avStreamFPS:(AVStream*)st defaultTime:(CGFloat)defaultTimeBase fps:(CGFloat*)pFPS timeBase:(CGFloat*)pTimeBase
{
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.den && st->codec->time_base.num)
        timebase = av_q2d(st->codec->time_base);
    else
        timebase = defaultTimeBase;
    DLog(@"timebase:%f",timebase);
    if (st->codec->ticks_per_frame != 1)
    {
        DLog(@"WARNING:st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
    }
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
}

#pragma mark 开启P2P
-(void)startP2PServer:(NSString*)nsDevId
{
    sdk = [PPSHAREINIT getP2PSDK];
    _nNum=0;
    if (sdk==NULL)
    {
        DLog(@"没有解析出相应的IP");
        self.nError = 1;
        self.strError = XCLocalized(@"connectFail");
        [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:self];
        return;
    }
    if (!recv)
    {
        recv = new RecvFile(sdk,0,_nChannel);
    }
    recv->peerName = [nsDevId UTF8String];
    __weak XCDecoderNew *_weakSelf = self;
    __block int __nCodeType = _nCodeType ;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
       BOOL bReturn = recv->threadP2P(__nCodeType);
       if (bReturn)
       {
           _weakSelf.bP2P = YES;
           DLog(@"P2P打洞成功");
           if (_weakSelf.bTran)//close TRAN
           {
               DLog(@"关闭转发");
               recv->closeTran();
           }
           else
           {
               DLog(@"开始P2P接收码流");
               nConnectStatus = 1;
           }
       }
       else
       {
           _weakSelf.nNum++;
           if (!_weakSelf.bTran)//close TRAN
           {
               DLog(@"tran-p2p fail");
               if (_weakSelf.bNotify)
               {
                   if(_weakSelf.nNum==2)
                   {
                       recv->bDevDisConn = YES;
                       nConnectStatus = -1;
                       _weakSelf.nError = 1;
                       _weakSelf.strError = XCLocalized(@"connectFail");
                       [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:_weakSelf];
                   }
               }
           }
           else
           {
               DLog(@"等待转发");
           }
       }
   });

   dispatch_async(dispatch_get_global_queue(0, 0),
   ^{
       BOOL bReturn = recv->threadTran(__nCodeType);
       if (bReturn)
       {
           _weakSelf.bTran = YES;
           DLog(@"转发成功");
           //转发
           if (_weakSelf.bP2P)//close TRAN
           {
               DLog(@"P2P已成功,关闭转发");
               recv->closeTran();
           }
           else
           {
               DLog(@"P2P未成功,开始解码");
               nConnectStatus = 1;
           }
       }
       else
       {
           _weakSelf.nNum++;
           if (!_weakSelf.bP2P)//close TRAN
           {
               if (_weakSelf.bNotify)
               {
                   if(_weakSelf.nNum==2)
                   {
                       recv->bDevDisConn = YES;
                       nConnectStatus = -1;
                       _weakSelf.nError = 1;
                       _weakSelf.strError = XCLocalized(@"connectFail");
                       [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:_weakSelf];
                   }
               }
           }
       }
   });
}
#pragma mark 码流切换
-(BOOL)switchP2PCode:(int)nCode
{
    _bSwitch = NO;
    _nCodeType = nCode;
    if(recv)
    {
         BOOL bReturn = recv->swichCode(nCode);
         if(bReturn)
         {
             _playing = YES;
             _bSwitch = YES;
//             avcodec_flush_buffers(pCodecCtx);
             return YES;
         }
         else
         {
             self.nError = 2;
             self.strError = XCLocalized(@"streamSetFail");
             [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:self];
             return NO;
         }
    }
    return NO;
}

-(CGFloat)frameWidth
{
    return _bIsDecoding ? pCodecCtx->width : 0;
}
-(CGFloat)frameHeight
{
    return _bIsDecoding ? pCodecCtx->height : 0;
}
-(void)destorySDK
{
    _destorySDK = YES;
}
-(void)dealloc
{
    if(recv)
    {
        recv->StopRecv();
        recv = NULL;
    }
    if (_destorySDK)
    {
        DLog(@"释放了");
        [PPSHAREINIT setP2PSDKNull];
    }
    [self closeFile];
    DLog(@"释放");
}
-(void)closeFile
{
    @synchronized(_videoArray)
    {
        [_videoArray removeAllObjects];
    }
    _videoStream = -1;
    if (pVideoFrame)
    {
        av_free(pVideoFrame);
        pVideoFrame = NULL;
    }
    if (pCodecCtx)
    {
        [[PPSHAREINIT getTheLock] lock];
        avcodec_close(pCodecCtx);
        [[PPSHAREINIT getTheLock] unlock];
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

-(void)releaseDecode
{
    DLog(@"外面改了");
    _playing = NO;
    _bNotify = NO;
    if(recv)
    {
        recv->sendheartinfoflag = NO;
        recv->bDevDisConn = YES;
        recv->bExit = YES;
    }
}

#pragma mark rgb
- (BOOL) setupScaler
{
    [self closeScaler];
    DLog(@"%d-%d",pCodecCtx->width,pCodecCtx->height);
    _pictureValid = avpicture_alloc(&_picture,
                                    PIX_FMT_RGB24,
                                    pCodecCtx->width,
                                    pCodecCtx->height) == 0;
//    if (!_pictureValid)
//        return NO;
    
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
    
    if (&_picture)
    {
        avpicture_free(&_picture);
    }
}

-(BOOL) setupVideoFrameFormat: (KxVideoFrameFormat) format
{
    if (_videoFrameFormat == KxVideoFrameFormatYUV)
    {
        return YES;
    }
    return NO;
}

#pragma mark 录像开始
-(void)recordStart:(NSString*)strPath name:(NSString*)strDevName
{
    if (recv)
    {
  //      nStartNum = pCodecCtx->frame_number;
        recv->startRecord(_moviePosition,[strPath UTF8String],[strDevName UTF8String]);
    }
}
#pragma mark 录像停止
-(void)recordStop
{
    if(recv)
    {
   //     NSInteger nAllFrameNumber = pCodecCtx->frame_number - nStartNum;
        recv->stopRecord(_moviePosition,0,25);
    }
}

#pragma mark 云台指令
-(void)sendPtzCmd:(int)nPtzCmd
{
    if(recv)
    {
        PtzControlMsg ptzCon;
        ptzCon.ptzcmd = (PTZCONTROLTYPE)nPtzCmd;
        ptzCon.channel = _nChannel;
        recv->sendPtzControl(&ptzCon);
    }
}

-(int)getRealType
{
    if(_bP2P)
    {
        return 1;
    }
    else
    {
        return 2;
    }
}

@end
