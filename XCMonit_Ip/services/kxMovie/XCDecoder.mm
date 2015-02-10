//
//  XCDecoder.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-13.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "XCDecoder.h"
#import "P2PSDKService.h"
#import "UtilsMacro.h"

#import "xcnotification.h"
#import "P2PInitService.h"
#include <sys/time.h>
#import "KxAudioManager.h"
#import <Accelerate/Accelerate.h>

extern "C"
{
    #include "libswresample/swresample.h"
    #include "libavformat/avformat.h"
    #include "libswscale/swscale.h"
}

#define P2PSHAREDINIT  [P2PInitService sharedP2PInitService]
using namespace std;

NSArray *collectStreams(AVFormatContext *formatCtx, enum AVMediaType codecType)
{
    NSMutableArray *ma = [NSMutableArray array];
    for (NSInteger i = 0; i < formatCtx->nb_streams; ++i)
        if (codecType == formatCtx->streams[i]->codec->codec_type)
            [ma addObject: [NSNumber numberWithInteger: i]];
    return [ma copy];
}

void avStreamFPSTimeBase(AVStream *st, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
{
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.den && st->codec->time_base.num)
        timebase = av_q2d(st->codec->time_base);
    else
        timebase = defaultTimeBase;
    
    if (st->codec->ticks_per_frame != 1) {
        NSLog(@"WARNING: st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
        //timebase *= st->codec->ticks_per_frame;
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

int readFile(void *opaque, uint8_t *buf, int buf_size)
{
    int size = buf_size;
    int ret = -1;
    struct timeval tv;
    gettimeofday(&tv,NULL);
    FILE *recordFile = (FILE *)opaque;
    do{
        size = fread(buf, 1, 1024, recordFile);
        if (size>0)
        {
            ret = 0;
        }
        else if(size==0)
        {
            DLog(@"文件读取完毕");
            return -1;
        }
    }while(ret);
    return size;
}

int read_data(void *opaque, uint8_t *buf, int buf_size)
{
    int size = buf_size;
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
        @synchronized(recvInfo->aryVideo)
        {
            if (recvInfo->aryVideo.count>0)
            {
                NSData *data = [recvInfo->aryVideo objectAtIndex:0];
                size = data.length;
                memcpy(buf, [data bytes], data.length);
                size = data.length;
                [recvInfo->aryVideo removeObjectAtIndex:0];
                ret = 0;
            }
        }
        if(result.tv_sec-tv.tv_sec>=7)
        {
            DLog(@"退出了");
            return -1;
        }
    }while(ret);
    return size;
}

NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength:width * height]; //[NSMutableData dataWithLength: width * height];
    Byte *dst = (Byte *)md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

@interface XCDecoder()
{

    AVFormatContext     *pFormatCtx;
    AVCodecContext      *pSubtitleCodecCtx;
    AVCodecContext      *pAudioCodecCtx;
    AVCodecContext      *pCodecCtx;
    
    AVFrame             *pVideoFrame;
    AVFrame             *pAudioFrame;
    BOOL                bInitPic;
    dispatch_queue_t    _dispatchQueue;
    dispatch_queue_t    _dispatch_queue;
    BOOL                bFirst;
    KxVideoFrameFormat  _videoFrameFormat;
    P2PSDKClient        *sdk;
    RecvFile            *recv;
    BOOL                bDestorySDK;
    AVPicture picture;
    struct SwsContext *img_convert_ctx;
    int nOutWidth,nOutHeight;
    BOOL bNotify;
    int _videoStream,_audioStream,_subtitleStream;
    NSUInteger _nFormat;
    CGFloat             _position;
    CGFloat             _videoTimeBase,_audioTimeBase;
    NSArray             *_videoStreams;
    NSArray             *_audioStreams;
    NSArray             *_subtitleStreams;

    NSDictionary        *_info;
    NSUInteger          _artworkStream,_subtitleASSEvents;
    void *_swrBuffer;
    SwrContext          *_swrContext;
    NSUInteger          _swrBufferSize;
    AVPacket            *_packet;
    CGFloat  pts;
    FILE *file_record;
    size_t file_size;
    int nConnectStatus;
    
    CGFloat _bufferedDuration;
    CGFloat _minDuration;
    CGFloat _maxDuration;
}

@property (readwrite) BOOL isEOF;
@property (readwrite) BOOL bIsDecoding;
@property (nonatomic,strong) NSMutableArray *videoArray;
@property (nonatomic,assign) BOOL playing;
@property (nonatomic,assign) BOOL decoding;

-(void)startP2PServer:(NSString*)nsDevId;

@end
#define kMaxDuration    0.07
#define kMinDuration    0.02


@implementation XCDecoder

-(id)init
{
    self = [super init];
    if (self)
    {
        self.isEOF = NO;
        bNotify = YES;
        bDestorySDK = NO;
    }
    return self;
}
#pragma mark 初始化设备信息
-(id)initWithNO:(NSString *)strNO format:(NSUInteger)nFormat
{
    self = [super init];
    self.isEOF = NO;
    _nFormat = nFormat;
    bNotify = YES;
    bDestorySDK = NO;
    
    __block NSString *weakNo = strNO;
    [P2PSHAREDINIT NewQueue];
    __weak XCDecoder *__weakSelf = self;
    nConnectStatus = 0;
    dispatch_async(dispatch_get_global_queue(0, 0), ^
    {
        [__weakSelf startP2PServer:weakNo];
        [__weakSelf initVideoParam];
    });
    return self;
}

#pragma mark 修改play函数
-(void)startPlay
{
    DLog(@"开启播放");
    if (_playing) {
        return;
    }
    _dispatch_queue = dispatch_queue_create("com.xzl.newdecode", DISPATCH_QUEUE_CONCURRENT);
    _decoding = NO;

    _playing = YES;
    [self asyncDecodeFrames];
    __weak XCDecoder *wearSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (1.0/100) * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
    {
       if(wearSelf.playing)
       {
           [wearSelf tick];
       }
    });
}
#pragma mark 持续解码
-(void)tick
{
    while(self.playing)
    {
        const NSUInteger leftFrames = _videoArray.count;
        if (!leftFrames)
        {
            [self asyncDecodeFrames];
        }
        [NSThread sleepForTimeInterval:1/_fps];
    }
}

#pragma mark 解码调用与添加解码后的数据
- (void) asyncDecodeFrames
{
    if (self.decoding)
    {
        return;
    }
    __weak XCDecoder *wearSelf = self;
    dispatch_async(_dispatch_queue, ^{
        wearSelf.decoding = YES;
        if (!wearSelf.playing)
        {
            return ;
        }
        BOOL good = YES;
        while (good)
        {
            good = NO;
            NSArray *frames = [wearSelf decodeFrames];
            if(frames.count)
            {
                good = [wearSelf addFrames:frames];
            }
            frames = nil;
        }
        wearSelf.decoding = NO;
    });
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
    return self.playing && _bufferedDuration < _minDuration;
}
#pragma mark 保留，会造成对象retain
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
    return frame;
}
#pragma mark 返回视频集合
-(NSMutableArray*)getVideoArray
{
    return _videoArray;
}

-(void)clearDuration:(CGFloat)duration
{
//    _bufferedDuration -= duration;
}














#pragma mark 本地操作   播放录像
-(id)initWithPath:(NSString*)strPath
{
    self = [super init];
    self.isEOF = NO;
    bNotify = YES;
    bDestorySDK = NO;
    return self;
}
#pragma mark 解码整流程
- (BOOL) openDecoder: (NSString *) path
            error: (NSError **) perror
{
    pFormatCtx = NULL;
    DLog(@"path:%@",path);
    kxMovieError errCode = [self openfile:path];
    if (errCode == kxMovieErrorNone)
    {
        kxMovieError videoErr = [self openVideoStream];
        if (videoErr != kxMovieErrorNone)
        {
            errCode = videoErr;
        }
    }
    
    if (errCode != kxMovieErrorNone)
    {
        [self closeFile];
        NSString *errMsg =[DecoderPublic errorMessage:errCode];//(errCode);
        NSLog(@"%@, %@", errMsg, path.lastPathComponent);
        if (perror)
            *perror = [DecoderPublic kxmovieError:errCode str:errMsg];
        return NO;
    }
    _bIsDecoding = YES;
    _videoFrameFormat = KxVideoFrameFormatYUV;
    pts = 0;
    return YES;
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
        avcodec_close(pCodecCtx);
        pCodecCtx = NULL;
    }
    if (pFormatCtx) {
        
        pFormatCtx->interrupt_callback.opaque = NULL;
        pFormatCtx->interrupt_callback.callback = NULL;
        
        avformat_close_input(&pFormatCtx);
        pFormatCtx = NULL;
    }
    fclose(file_record);
}

#pragma mark P2P与中转建立连接使用方式
-(BOOL)initVideoParam
{
    while (1)
    {
        if (nConnectStatus == 1)
        {
            break;
        }else if(nConnectStatus == -1)
        {
            return NO;
        }
        [NSThread sleepForTimeInterval:0.5f];
    }
    _videoArray = [NSMutableArray array];
    
    pFormatCtx = NULL;
    _bIsDecoding = NO;
    AVInputFormat* pAvinputFmt = NULL;
    AVCodec         *pCodec = NULL;
    AVIOContext		*pb = NULL;
    int				streamNumber = -1;
    int i;
    uint8_t	*buf = NULL;
    buf = (uint8_t*)malloc(sizeof(uint8_t)*256);
    av_register_all();
    avcodec_register_all();
    pb = avio_alloc_context(buf, 256, 0, recv, read_data,NULL, NULL);
    
    pAvinputFmt = av_find_input_format("H264");
    pFormatCtx = avformat_alloc_context();
    pFormatCtx->pb = pb;
    pFormatCtx->max_analyze_duration = 1 * AV_TIME_BASE;
    if(avformat_open_input(&pFormatCtx, "", pAvinputFmt, NULL) != 0 ){
        goto Release_avformat_open_input;
    }
    if( avformat_find_stream_info(pFormatCtx, NULL ) < 0 )
    {
        goto Release_avformat_open_input;
    }
    for (i = 0; i < pFormatCtx->nb_streams;i++)
    {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            streamNumber = i;
            break;
        }
    }
    if( streamNumber == -1 )
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
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0 )
    {
        return NO;
    }
    pVideoFrame = avcodec_alloc_frame();
    if( pVideoFrame == NULL ){
        return NO;
    }
    avStreamFPSTimeBase(pFormatCtx->streams[_videoStream], 0.04, &_fps, &_videoTimeBase);
    DLog(@"fps:%f",_fps);
    _bIsDecoding = YES;
    _videoFrameFormat = KxVideoFrameFormatYUV;
    //FPS赋值
    return YES;
    
Release_avformat_open_input:
    
    avformat_free_context(pFormatCtx);
    pFormatCtx = NULL;
    av_free(pb);
    if (bNotify)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:NSLocalizedString(@"nostream", nil)];
    }
    return NO;
}


- (NSUInteger) frameWidth
{
    return _bIsDecoding ? pCodecCtx->width : 0;
}

- (NSUInteger) frameHeight
{
    return _bIsDecoding ? pCodecCtx->height : 0;
}

#pragma mark 先一步停止P2P或者转发操作，在dealloc前调用
-(void)releaseDecode
{
    DLog(@"外面改了");
    bNotify = NO;
    if(recv)
    {
        recv->sendheartinfoflag = NO;
        recv->bDevDisConn = YES;
        recv->bExit = YES;
    }
}
#pragma mark 销毁Decode
-(void)dealloc
{
    [self recordStop];
    if(recv)
    {
        recv->StopRecv();
        [P2PSHAREDINIT free_queue:recv->mReciveQueue];
        recv->mReciveQueue = NULL;
        recv = NULL;
    }
//    if (sdk)
//    {
//        sdk->DeInitialize();
//    }
    if (bDestorySDK)
    {
        [P2PSHAREDINIT setP2PSDKNull];
    }
    [self closeFile];
}

#pragma mark 收到进入后台消息，必须销毁P2PSDKClient
-(void)destorySDK
{
    bDestorySDK = YES;
}




#define   kServerName  "58.96.171.231"
#pragma mark P2P连接，不再更改
-(void)startP2PServer:(NSString*)nsDevId
{
    sdk = [P2PSHAREDINIT getP2PSDK];
    char myId[20] = {0};
    srand(time(NULL));
    long  randomNum = rand();
    sprintf(myId, "ios_%ld", randomNum);
    bool ret = sdk->Initialize([NSLocalizedString(@"p2pserver", "p2p server") UTF8String], myId);
    DLog(@"myid:%s",myId);
    if(ret)
    {
        NSLog(@"sdk Inialize success \n");
    }
    else
    {
        NSLog(@"%s sdk Inialize failed \n", [nsDevId UTF8String]);
    }
    if (!recv)
    {
        recv = new RecvFile(sdk,0,0);
    }
    recv->peerName = [nsDevId UTF8String];
    dispatch_async(dispatch_get_global_queue(0, 0), ^
   {
       //默认2
       BOOL bReturn = recv->startGcd(_nFormat,2);
       if (!bReturn)
       {
           nConnectStatus = -1;
           recv->bDevDisConn = YES;
           if (bNotify)
           {
               [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:NSLocalizedString(@"connectFail", "connectFail")];
           }
       }
       else
       {
           nConnectStatus = 1;
       }
   });
}
#pragma mark 码流切换
-(void)switchP2PCode:(int)nCode
{
    _nSwitchcode = NO;
    __weak XCDecoder *_weakSelf = self;
    if(recv)
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            BOOL bReturn = recv->swichCode(nCode);
            if(bReturn)
            {
                _weakSelf.nSwitchcode = YES;
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:NSSWITCH_P2P_FAIL_VC object:NSLocalizedString(@"switchError", nil)];
            }
        });

    }
}

#pragma mark 解码函数,返回NSMuTableArray
-(NSMutableArray*)decodeFrames
{
    int gotframe;
    AVPacket packet;
    av_init_packet(&packet);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL bFinish = NO;
    int nRef = 0;
    CGFloat minDuration = 0;
    CGFloat decodedDuration = 0;
    while (!bFinish)
    {
        if (!bNotify)
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
                    _position = frameVideo.position;
                    decodedDuration += frameVideo.duration;
                    if (decodedDuration > minDuration)
                    {
                        bFinish = YES;
                    }
                }
                frameVideo = nil;
            }
            if (0 == len || -1 == len)
            {
                av_free_packet(&packet);
                break;
            }
        }
        else
        {
            //结束
            _isEOF = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:NSLocalizedString(@"Disconnect", "Disconnect")];
            break;
        }
    }
    av_free_packet(&packet);
    return result;
}


#pragma mark 退出标志
-(BOOL)getExit
{
    if (recv) {
        return recv->bExit;
    }
    return NO;
}
#pragma mark 录像开始
-(void)recordStart
{
    if (recv)
    {
        recv->startRecord(pts);
    }
}
#pragma mark 录像停止
-(void)recordStop
{
    if(recv)
    {
        recv->stopRecord(pts);
    }
}

#pragma mark position表示时间戳
- (CGFloat) position
{
    return _position;
}
#pragma mark 快进控制
- (void) setPosition: (CGFloat)seconds
{
    _position = seconds;
    _isEOF = NO;
	   
    if (_videoStream != -1)
    {
        long nSize = floor(((float)seconds/_allTime)*file_size);
        fseek(file_record, nSize, SEEK_SET);
        pts = seconds;
        avcodec_flush_buffers(pCodecCtx);
    }
}


#pragma mark 录像操作 ffmpeg
-(kxMovieError)openfile:(NSString*)strPath
{
    av_register_all();
    avcodec_register_all();
    NSString *strFile = [NSString stringWithFormat:@"%@/record/%@",kLibraryPath,strPath];
    file_record = fopen([strFile UTF8String], "r");
    if(file_record==nil)
    {
        DLog(@"打开文件失败");
        return kxMovieErrorOpenFile;
    }
    long curpos;
    curpos = ftell(file_record);
    fseek(file_record, 0L, SEEK_END);
    file_size = ftell(file_record);
    fseek(file_record, curpos, SEEK_SET);
    
    pFormatCtx = NULL;
    _bIsDecoding = NO;
    AVInputFormat* pAvinputFmt = NULL;
    AVIOContext		*pb = NULL;
    uint8_t	*buf = NULL;
    buf = (uint8_t*)malloc(sizeof(uint8_t)*1024);
    av_register_all();
    avcodec_register_all();
    pb = avio_alloc_context(buf, 1024, 0, file_record, readFile,NULL, NULL);
    pAvinputFmt = av_find_input_format("H264");
    pFormatCtx = avformat_alloc_context();
    pFormatCtx->pb = pb;
    pFormatCtx->max_analyze_duration = 1 * AV_TIME_BASE;
    if(avformat_open_input(&pFormatCtx, "", pAvinputFmt, NULL) != 0 ){
        goto Release_format_input;
    }
    if(avformat_find_stream_info(pFormatCtx, NULL ) < 0 )
    {
        goto Release_format_input;
    }
    return kxMovieErrorNone;
Release_open_input:
    return kxMovieErrorOpenFile;
Release_format_input:
    DLog(@"打开文件失败，或者无法获取到视频流");
    [self closeFile];
    return kxMovieErrorStreamNotFound;
}
#pragma mark 视频流操作
- (kxMovieError) openVideoStream
{
    kxMovieError errCode = kxMovieErrorStreamNotFound;
    _videoStream = -1;
    _artworkStream = -1;
    _videoStreams = collectStreams(pFormatCtx, AVMEDIA_TYPE_VIDEO);
    for (NSNumber *n in _videoStreams)
    {
        
        const NSUInteger iStream = n.integerValue;
        
        if (0 == (pFormatCtx->streams[iStream]->disposition & AV_DISPOSITION_ATTACHED_PIC))
        {
            errCode = [self openVideoCode:iStream];
            if (errCode == kxMovieErrorNone)
            {
                break;
            }
        } else
        {
            
            _artworkStream = iStream;
        }
    }
    return errCode;
}
#pragma mark 打开视频流
- (kxMovieError) openVideoCode:(NSInteger) videoStream
{
    // get a pointer to the codec context for the video stream
    pCodecCtx = pFormatCtx->streams[videoStream]->codec;
    // find the decoder for the video stream
    AVCodec *codec = avcodec_find_decoder(pCodecCtx->codec_id);
    if (!codec)
    {
        return kxMovieErrorCodecNotFound;
    }
    if (avcodec_open2(pCodecCtx, codec, NULL) < 0)
        return kxMovieErrorOpenCodec;
    
    pVideoFrame = avcodec_alloc_frame();
    
    if (!pVideoFrame) {
        avcodec_close(pCodecCtx);
        return kxMovieErrorAllocateFrame;
    }
    _videoStream = videoStream;
    
    // determine fps
    AVStream *st = pFormatCtx->streams[_videoStream];
    avStreamFPSTimeBase(st, 0.04, &_fps, &_videoTimeBase);
    return kxMovieErrorNone;
}
#pragma mark yuv 转换
- (KxVideoFrame *) handleVideoFrame
{
    if (!pVideoFrame->data[0])
        return nil;
    KxVideoFrame *frame = [[KxVideoFrame alloc] init];
    KxVideoFrameYUV * yuvFrame = [[KxVideoFrameYUV alloc] init];
    yuvFrame.luma = copyFrameData(pVideoFrame->data[0],
                                  pVideoFrame->linesize[0],
                                  pCodecCtx->width,
                                  pCodecCtx->height);
    yuvFrame.chromaB = copyFrameData(pVideoFrame->data[1],
                                     pVideoFrame->linesize[1],
                                     pCodecCtx->width / 2,
                                     pCodecCtx->height / 2);
    yuvFrame.chromaR = copyFrameData(pVideoFrame->data[2],
                                     pVideoFrame->linesize[2],
                                     pCodecCtx->width / 2,
                                     pCodecCtx->height / 2);
    frame = yuvFrame;
    frame.width = pCodecCtx->width;
    frame.height = pCodecCtx->height;

    frame.duration = 1.0 / _fps;
    pts += frame.duration;
    frame.position = pts;
    
    return frame;
}


#pragma mark  opengl YUV方式显示
-(BOOL) setupVideoFrameFormat: (KxVideoFrameFormat) format
{
    if (CURRENT_DISPLAY == KxVideoFrameFormatYUV)
    {
        _videoFrameFormat = KxVideoFrameFormatYUV;
    }
    else
    {
        _videoFrameFormat = KxVideoFrameFormatRGB;
    }
    return YES;
}

@end




