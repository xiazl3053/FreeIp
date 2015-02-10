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
extern "C"
{
    #include "libswresample/swresample.h"
    #include "libavformat/avformat.h"
    #include "libswscale/swscale.h"
}


int read_code(void *opaque, uint8_t *buf, int buf_size)
{
    int size = buf_size;
 //   DLog(@"size:%d",buf_size);
    int ret = -1;
    struct timeval tv;
    gettimeofday(&tv,NULL);
    RecvFile *recvInfo = (RecvFile *)opaque;
    do{
        if(!recvInfo || recvInfo->bDevDisConn)
        {
            return -1;
        }
        struct timeval result;
        gettimeofday(&result,NULL);

        if (recvInfo->aryVideo.count>0)
        {
            NSData *data = [recvInfo->aryVideo objectAtIndex:0];
            size = data.length;
            memcpy(buf, [data bytes], data.length);
            size = data.length;
            @synchronized(recvInfo->aryVideo)
            {
                [recvInfo->aryVideo removeObjectAtIndex:0];
            }
            ret = 0;
        }
        if(result.tv_sec-tv.tv_sec>=5)
        {
            DLog(@"退出了");
            return -1;
        }
    }while(ret);
    return size;
}

NSData * copyFrameDataNew(UInt8 *src, int linesize, int width, int height)
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
    struct SwsContext   *_swsContext;
    AVPicture           _picture;
    BOOL                _pictureValid;
    
    
    int                 nConnectStatus;
    int                 nFormat;
    int                 _videoStream;
    //
    AVFrame            *pVideoFrame;
    
    BOOL               _bIsDecoding;
    
    CGFloat            _videoTimeBase;
    bool               _destorySDK;
    BOOL               _isEOF;
    NSUInteger    _tickCounter;
    int nFFMpegStatus;
    
    float _bufferedDuration;
    CGFloat _minBufferedDuration;
    CGFloat _maxBufferedDuration;
    CGFloat _moviePosition;
}
@property (nonatomic,assign) BOOL     decoding;
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
-(id)initWithFormat:(KxVideoFrameFormat)format
{
    self = [super init];
    _bNotify = YES;
    nFormat = 1;
    _destorySDK = NO;
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




#pragma mark 解码操作   P2P方式
-(BOOL)initVideoParam
{
    DLog(@"开始时间");
    while (1)
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
            return NO;
        }
    }
    pthread_mutex_init(&mutex,NULL);
    DLog(@"开始解码方法:%@",_strNO);
    nFFMpegStatus = 1;
    _videoArray = [NSMutableArray array];
    _bIsDecoding = NO;
    _minBufferedDuration = 0.01f;
    _maxBufferedDuration = 0.05f;
    AVInputFormat* pAvinputFmt = NULL;
    AVCodec         *pCodec = NULL;
    AVIOContext		*pb = NULL;
    int				streamNumber = -1;
    int i;
    uint8_t	*buf = NULL;
    buf = (uint8_t*)malloc(sizeof(uint8_t)*256);
    av_register_all();
    avcodec_register_all();
    
    pb = avio_alloc_context(buf,256,0,recv,read_code,NULL, NULL);
    pAvinputFmt = av_find_input_format("H264");
    pFormatCtx = avformat_alloc_context();
    pFormatCtx->pb = pb;
    pFormatCtx->max_analyze_duration = 1 * AV_TIME_BASE;
    pthread_mutex_lock(&mutex);
    if(avformat_open_input(&pFormatCtx, "", pAvinputFmt, NULL) != 0 )
    {
        goto Release_avformat_open_input;
    }
    if(avformat_find_stream_info(pFormatCtx, NULL ) < 0 )
    {
        goto Release_avformat_open_input;
    }
    pthread_mutex_unlock(&mutex);
    
    for (i = 0; i < pFormatCtx->nb_streams;i++)
    {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            streamNumber = i;
            break;
        }
    }
    if(streamNumber == -1 )
    {
        DLog(@"找不到视频数据");
        return NO;
    }
    pCodecCtx = pFormatCtx->streams[streamNumber]->codec;
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec == nil)
    {
        return NO;
    }
    DLog(@"找到码流");
    pthread_mutex_lock(&mutex);
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0 )
    {

        return NO;
    }
    pthread_mutex_unlock(&mutex);
    
    if(pCodec->capabilities&CODEC_CAP_TRUNCATED)
    {
        pCodecCtx->flags |= CODEC_FLAG_TRUNCATED;
    }
    pVideoFrame = avcodec_alloc_frame();
    if( pVideoFrame == NULL ){
        return NO;
    }
    [self avStreamFPS:pFormatCtx->streams[_videoStream] defaultTime:0.04 fps:&_fFPS timeBase:&_videoTimeBase];
    DLog(@"fps:%f",_fFPS);
    _bIsDecoding = YES;
 //   _videoFrameFormat = KxVideoFrameFormatYUV;
    //转换成rgb
    //FPS赋值
    nFFMpegStatus = 2;
    
    return YES;
    
Release_avformat_open_input:
    
    avformat_free_context(pFormatCtx);
    pFormatCtx = NULL;
    av_free(pb);
    if (_bNotify)
    {
        self.nError = 2;
        _strError = NSLocalizedString(@"nostream", nil);
        [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:self];
    }
    return NO;
    
    
}

#pragma mark  play函数
-(void)startPlay
{
    DLog(@"开启播放");
    _dispatch_queue = dispatch_queue_create("com.xzl.newdecode", DISPATCH_QUEUE_CONCURRENT);
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
    if(!_playing){return;}
        

    const NSUInteger leftFrames = _videoArray.count;
    if (!leftFrames)
    {
        [self asyncDecodeFrames];
    }
    
    float nTime = _fFPS;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0/nTime * NSEC_PER_SEC);
    __weak XCDecoderNew *weakSelf = self;
    dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
    {
       [weakSelf tick];
    });
}


-(void)pauseVideo
{
    
}


- (void) asyncDecodeFrames
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
    while (good)
    {
        good = NO;
        NSArray *frames = [self decodeFrames];
        if(frames.count)
        {
            good = [self addFrames:frames];
        }
        frames = nil;
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
    return _playing && _bufferedDuration < _maxBufferedDuration;
}

-(KxVideoFrame*)getNextFrame
{
    KxVideoFrame *frame;
    @synchronized(_videoArray)
    {
        if (_videoArray.count > 0) {
            frame = _videoArray[0];
            [_videoArray removeObjectAtIndex:0];
        }
    }
    if (frame)
    {
        _bufferedDuration -= frame.duration;
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

    while (!bFinish)
    {
        if (!_bNotify)
        {
            return result;
        }

        nRef =av_read_frame(pFormatCtx, &packet);
        
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
                frameVideo = nil;
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
            _strError = NSLocalizedString(@"Disconnect", "Disconnect");
            [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:self];
            break;
        }
        av_free_packet(&packet);
    }
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
        
    } else {
        
        if (!_swsContext &&
            ![self setupScaler]) {
            
            NSLog(@"fail setup video scaler");
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
    
    if (st->codec->ticks_per_frame != 1)
    {
        NSLog(@"WARNING:st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
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
    char myId[20] = {0};
    srand(time(NULL));
    long  randomNum = rand();
    sprintf(myId, "ios_%ld", randomNum);
    BOOL ret = NO;
    DLog(@"strAddress:%@",PPSHAREINIT.strAddress);
    if(PPSHAREINIT.strAddress)
    {
        ret = sdk->Initialize([PPSHAREINIT.strAddress UTF8String], myId);
    }
    else
    {
        BOOL bFlag = [PPSHAREINIT getIPWithHostName:NSLocalizedString(@"p2pserver", "p2p server")];
        DLog(@"NSLocalizedString-p2pserver:%@",NSLocalizedString(@"p2pserver", "p2p server"));
        if (bFlag)
        {
            ret = sdk->Initialize([PPSHAREINIT.strAddress UTF8String], myId);
        }
        else
        {
            self.nError = 1;
            self.strError = NSLocalizedString(@"connectFail", "connectFail");
            [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:self];
            nConnectStatus = -1;
            return ;
        }
    }
    DLog(@"myid:%s",myId);
    if(ret)
    {
        NSLog(@"sdk Inialize success \n");
    }
    else
    {
        NSLog(@"%s sdk Inialize failed \n", [nsDevId UTF8String]);
        nConnectStatus = -1;
        self.nError = 1;
        self.strError = NSLocalizedString(@"connectFail", "connectFail");
        [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:self];
        return ;
    }
    if (!recv)
    {
        recv = new RecvFile(sdk,0,_nChannel);
    }
    recv->peerName = [nsDevId UTF8String];
    __weak XCDecoderNew *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^
    {
        //默认选择辅码流
        BOOL bReturn = recv->startGcd(nFormat,2);
       if (!bReturn)
       {
           nConnectStatus = -1;
           recv->bDevDisConn = YES;
           if (_bNotify)
           {
               weakSelf.nError = 1;
               weakSelf.strError = NSLocalizedString(@"connectFail", "connectFail");
               [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_DVR_FAIL_VC object:weakSelf];
           }
       }
       else
       {
           DLog(@"连接成功");
           nConnectStatus = 1;
       }
    });
    
}
#pragma mark 码流切换
-(void)switchP2PCode:(int)nCode
{
    _bSwitch = NO;
    __weak XCDecoderNew *_weakSelf = self;
    if(recv)
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            BOOL bReturn = recv->swichCode(nCode);
            if(bReturn)
            {
                _weakSelf.bSwitch = YES;
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:NSSWITCH_P2P_FAIL_VC object:@"码流切换失败"];
            }
        });
        
    }
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
    @synchronized(_videoArray)
    {
        [_videoArray removeAllObjects];
    }
    if(recv)
    {
        recv->StopRecv();
        [PPSHAREINIT free_queue:recv->mReciveQueue];
        recv->mReciveQueue = NULL;
        recv = NULL;
    }
    if (_destorySDK)
    {
        [PPSHAREINIT setP2PSDKNull];
    }
    [self closeFile];
}
-(void)closeFile
{
    _videoStream = -1;
    if (pVideoFrame)
    {
        av_free(pVideoFrame);
        pVideoFrame = NULL;
    }
    if (pCodecCtx)
    {
        pthread_mutex_lock(&mutex);
        avcodec_close(pCodecCtx);
        pthread_mutex_unlock(&mutex);
        pCodecCtx = NULL;
    }
    
    if (pFormatCtx)
    {
        pFormatCtx->interrupt_callback.opaque = NULL;
        pFormatCtx->interrupt_callback.callback = NULL;
        dispatch_sync(dispatch_get_global_queue(0, 0),
        ^{
            avformat_close_input(&pFormatCtx);
        });
        
        pFormatCtx = NULL;
    }
    pthread_mutex_destroy(&mutex);
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
    
    if (_pictureValid) {
        avpicture_free(&_picture);
        _pictureValid = NO;
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


//#ifdef _FOR_DEBUG_
//-(BOOL) respondsToSelector:(SEL)aSelector {
//    printf("SELECTOR: %s\n", [NSStringFromSelector(aSelector) UTF8String]);
//    return [super respondsToSelector:aSelector];
//}
//#endif



#pragma mark 录像开始
-(void)recordStart
{
    if (recv)
    {
        recv->startRecord(_moviePosition);
    }
}
#pragma mark 录像停止
-(void)recordStop
{
    if(recv)
    {
        recv->stopRecord(_moviePosition);
    }
}




@end
