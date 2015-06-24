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
#include "P2PSDK.h"
extern "C"
{
    #include "libavformat/avformat.h"
    #include "libswscale/swscale.h"
}

#define P2PSHAREDINIT  [P2PInitService sharedP2PInitService]

using namespace std;
int nTimeOut;

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
    
    DLog(@"timebase:%f",timebase);
    
    if (st->codec->ticks_per_frame != 1) {
        DLog(@"WARNING: st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
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
        size = (int)fread(buf, 1, 1024, recordFile);
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
    do
    {
        if(!recvInfo && recvInfo->bExit)
        {
            DLog(@"退出了 by recvInfo->bExit");
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
        if(result.tv_sec-tv.tv_sec>=nTimeOut)
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
    AVCodecContext      *pCodecCtx;
    AVFrame             *pVideoFrame;
    AVFrame             *pNewVideoFrame;
    struct SwsContext   *_swsContext;
    AVPicture           _picture;

    P2PSDKClient        *sdk;
    RecvFile            *recv;
    
    BOOL                bDestorySDK;
    
    AVPicture picture;
    struct SwsContext *img_convert_ctx;
    int nOutWidth,nOutHeight;
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
    
    NSUInteger          _swrBufferSize;
    AVPacket            *_packet;
    
    CGFloat        fStartRecord;
    
    CGFloat  pts;
    FILE *file_record;
    size_t file_size;
    int nConnectStatus;
    BOOL     _pictureValid;
    BOOL  bPhoto;
    
    
    CGFloat _bufferedDuration;
    CGFloat _minDuration;
    CGFloat _maxDuration;
    BOOL bRecord;
    AVStream *video_stream;
    
    int video_stream_idx , audio_stream_idx ;
    NSInteger _nType ;
    
    NSInteger nsiFrame;
    CGFloat fSrcWidth,fSrcHeight;
}

@property (readwrite) BOOL isEOF;
@property (readwrite) BOOL bIsDecoding;
@property (nonatomic,strong) NSMutableArray *videoArray;
@property (nonatomic,assign) BOOL playing;
@property (nonatomic,assign) BOOL decoding;
@property (nonatomic,assign) BOOL bTran;
@property (nonatomic,assign) BOOL bP2P;
@property (nonatomic,assign) NSInteger nNum;
@property (nonatomic,assign) BOOL bNotify;

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
        _bNotify = YES;
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
    _bNotify = YES;
    bDestorySDK = NO;
    
    __block NSString *weakNo = strNO;
    __weak XCDecoder *__weakSelf = self;
    nConnectStatus = 0;
    bPhoto = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^
    {
        [__weakSelf startP2PServer:weakNo];
        [__weakSelf initVideoParam];
    });
    _videoFrameFormat = KxVideoFrameFormatYUV;
    return self;
}

#pragma mark 初始化设备信息  加入rgb参数
-(id)initWithNO:(NSString *)strNO format:(NSUInteger)nFormat videoFormat:(KxVideoFrameFormat)type
{
    self = [super init];
    [self initDecodeInfo:strNO format:nFormat videoFormat:type codeType:2];
    return self;
}

-(void)initDecodeInfo:(NSString *)strNO format:(NSUInteger)nFormat videoFormat:(KxVideoFrameFormat)type codeType:(NSInteger)nType
{
    self.isEOF = NO;
    _nFormat = nFormat;
    _bNotify = YES;
    bDestorySDK = NO;
    nTimeOut = 40;
    __block NSString *weakNo = strNO;
    __weak XCDecoder *__weakSelf = self;
    nConnectStatus = 0;
    _videoFrameFormat = type;
    _nType = nType;
    if (nFormat==1)
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^
        {
            [__weakSelf startP2PServer:weakNo];
            [__weakSelf initVideoParam];
        });
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^
        {
            [__weakSelf startTranServer:weakNo];
            [__weakSelf initVideoParam];
        });
    }
}

-(id)initWithNO:(NSString *)strNO format:(NSUInteger)nFormat videoFormat:(KxVideoFrameFormat)type codeType:(NSInteger)nType
{
    self = [super init];
    [self initDecodeInfo:strNO format:nFormat videoFormat:type codeType:nType];
    return self;
}

#pragma mark 本地操作   播放录像
-(id)initWithPath:(NSString*)strPath
{
    self = [super init];
    self.isEOF = NO;
    _bNotify = YES;
    bDestorySDK = NO;
    return self;
}

#pragma mark 录像解码开启
- (BOOL) openDecoder: (NSString *) path
            error: (NSError **) perror
{
    pFormatCtx = NULL;
    DLog(@"path:%@",path);
    kxMovieError errCode = [self openfile:path];    
    if (errCode != kxMovieErrorNone)
    {
        [self closeFile];
        NSString *errMsg =[DecoderPublic errorMessage:errCode];//(errCode);
        DLog(@"%@, %@", errMsg, path.lastPathComponent);
        if (perror)
            *perror = [DecoderPublic kxmovieError:errCode str:errMsg];
        return NO;
    }
    _bNotify = YES;
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
        DLog(@"释放codecCtx");
        avcodec_close(pCodecCtx);
        pCodecCtx = NULL;
    }
    if (pFormatCtx)
    {
        pFormatCtx->interrupt_callback.opaque = NULL ;
        pFormatCtx->interrupt_callback.callback = NULL ;
        avformat_close_input(&pFormatCtx);
        pFormatCtx = NULL;
    }
    fclose(file_record);
}

#pragma mark P2P与中转建立连接使用方式
-(BOOL)initVideoParam
{
    while (YES)
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
    _bIsDecoding = YES;
    return YES;
}


- (NSUInteger) frameWidth
{
  //  return 354;
    return _bIsDecoding ? pCodecCtx->width : 352;
}

- (NSUInteger) frameHeight
{
 //   return 288;
    return _bIsDecoding ? pCodecCtx->height : 288;
}

#pragma mark 先一步停止P2P或者转发操作，在dealloc前调用
-(void)releaseDecode
{
    nTimeOut = 1;
    DLog(@"外面改了");
    _bNotify = NO;
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
    DLog(@"要结束");
    [self recordStop];
    if(recv)
    {
        recv->StopRecv();
        recv->mReciveQueue = NULL;
        recv = NULL;
    }
    if (bDestorySDK)
    {
        DLog(@"释放");
        [P2PSHAREDINIT setP2PSDKNull];
    }
    [self closeScaler];
    [self closeFile];
//    avformat_alloc_output_context2
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_SWITCH_TRAN_OPEN_VC object:nil];
}

#pragma mark 收到进入后台消息，必须销毁P2PSDKClient
-(void)destorySDK
{
    bDestorySDK = YES;
}

-(void)startTranServer:(NSString*)nsDevId
{
    sdk = [P2PSHAREDINIT getP2PSDK];
    if(sdk!=NULL)
    {
        DLog(@"sdk Inialize success \n");
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"connectFail")];
        DLog(@"%s sdk Inialize failed \n", [nsDevId UTF8String]);
        return ;
    }
    if (!recv)
    {
        recv = new RecvFile(sdk,0,0);
    }
    recv->peerName = [nsDevId UTF8String];
    __weak XCDecoder *_weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^
    {
       BOOL bReturn = recv->startGcd((int)_nFormat,(int)_nType);
       if (!bReturn)
       {
           nConnectStatus = -1;
           recv->bDevDisConn = YES;
           if (_weakSelf.bNotify)
           {
               [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"connectFail")];
           }
       }
       else
       {
           nConnectStatus = 1;
       }
   });
}

#pragma mark P2P连接，不再更改
-(void)startP2PServer:(NSString*)nsDevId
{
    sdk = [P2PSHAREDINIT getP2PSDK];
    _nNum = 0;
    if(sdk!=NULL)
    {
        DLog(@"sdk Inialize success \n");
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"connectFail")];
        DLog(@"%s sdk Inialize failed \n", [nsDevId UTF8String]);
        return ;
    }
    if (!recv)
    {
        recv = new RecvFile(sdk,0,0);
    }
    recv->peerName = [nsDevId UTF8String];
    __weak XCDecoder *_weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
   ^{
       BOOL bReturn = recv->threadP2P((int)_nType);
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
           DLog(@"P2P出现错误");
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
                       [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"connectFail")];
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
       BOOL bReturn = recv->threadTran((int)_nType);
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
                       [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"connectFail")];
                   }
               }
           }
       }
   });
}
#pragma mark 码流切换
-(void)switchP2PCode:(int)nCode
{
    DLog(@"目标码流:%d",nCode);
    _nSwitchcode = NO;

    __weak XCDecoder *__weakSelf = self;
    __block int __nCode = nCode;
    if(recv)
    {
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            BOOL bReturn = recv->swichCode(__nCode);
            if(bReturn)
            {
                __weakSelf.nSwitchcode = YES;
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"switchError")];
            }
        });
    }
}
int nInfoNum = 0;

#pragma mark 实时解码
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
    uint8_t *puf= (uint8_t*)malloc(500*1024);
    
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
                if (data.length < 500*1024)
                {
                    packet.size = (int)data.length;
                    memcpy(puf, [data bytes], data.length);
                    [recv->aryVideo removeObjectAtIndex:0];
                    data = nil;
                    packet.data = puf;
                }
                else
                {
                    packet.size = 0;
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
//                DLog(@"PSP PPS");
                continue;
            }
        }
        else
        {
            if(nTimeOut==1)
            {
                return result;
            }
            //结束
            _isEOF = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"Disconnect")];
            break;
        }
    }
    av_free_packet(&packet);
    free(puf);
    return result;
}


#pragma mark 录像解码函数
-(NSMutableArray*)record_decodeFrames
{
    int gotframe;
    AVPacket packet;
    av_init_packet(&packet);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL bFinish = NO;
    int nRef = 0;
    CGFloat minDuration = 0;
    CGFloat decodedDuration = 0;
 //   uint8_t *puf= (uint8_t*)malloc(100*1024);
    while (!bFinish)
    {
        if(!_bNotify)
        {
            return result;
        }
        nRef = av_read_frame(pFormatCtx, &packet);
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
            DLog(@"_strErr:%@",XCLocalized(@"Disconnect"));
            if(_bNotify)
            {
                _bNotify = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"Disconnect")];
            }
            break;
        }
    }
    av_free_packet(&packet);
//    free(puf);
    return result;
}


#pragma mark 退出标志
-(BOOL)getExit
{
    if (recv)
    {
        return recv->bExit;
    }
    return NO;
}
#pragma mark 录像开始
-(void)recordStart:(NSString*)strPath name:(NSString*)strDevName
{
    if (recv)
    {
        recv->startRecord(pts,[strPath UTF8String],[strDevName UTF8String]);
        bRecord = YES;
    }
}
#pragma mark 录像停止
-(void)recordStop
{
    if(recv && bRecord)
    {
        bRecord = NO;
        CGFloat fEnd = pts;
        recv->stopRecord(fEnd,0,_fps);
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
//        avcodec_flush_buffers(pCodecCtx);
    }
}


#pragma mark 录像操作 ffmpeg
-(kxMovieError)openfile:(NSString*)strPath
{
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
  
    avcodec_register_all();
    pb = avio_alloc_context(buf, 1024, 0, file_record, readFile,NULL, NULL);
    pAvinputFmt = av_find_input_format("H264");
    pFormatCtx = avformat_alloc_context();
    pFormatCtx->pb = pb;
    pFormatCtx->max_analyze_duration = 1 * AV_TIME_BASE;
    
    if(avformat_open_input(&pFormatCtx,[strFile UTF8String],pAvinputFmt, NULL) != 0 )
    {
        [self closeFile];
        DLog(@"打开码流失败");
        return kxMovieErrorStreamNotFound;
    }
    int i=0;
    for (i = 0; i < pFormatCtx->nb_streams;i++)
    {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            _videoStream = i;
            break;
        }
    }
    if( _videoStream == -1 )
    {
        DLog(@"找不到视频数据");
        return kxMovieErrorCodecNotFound;
    }
    pCodecCtx = pFormatCtx->streams[_videoStream]->codec;
    AVCodec *pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        return kxMovieErrorCodecNotFound;
    }
    pVideoFrame = avcodec_alloc_frame();
    pNewVideoFrame = avcodec_alloc_frame();
    if( pVideoFrame == NULL )
    {
        return kxMovieErrorCodecNotFound;
    }
    _fps = 25.0f;
    DLog(@"_fps:%f",_fps);
    return kxMovieErrorNone;
Release_open_input:
    return kxMovieErrorOpenFile;

}


-(UIImage *)capturePhoto
{

        [self setupScaler];
    
        sws_scale(_swsContext,
              (const uint8_t **)pNewVideoFrame->data,
              pNewVideoFrame->linesize,
              0,
              pCodecCtx->height,
              _picture.data,
              _picture.linesize);
    
        KxVideoFrameRGB *rgbFrame = [[KxVideoFrameRGB alloc] init];
        rgbFrame.linesize = _picture.linesize[0];
        rgbFrame.rgb = [NSData dataWithBytes:_picture.data[0]
                                      length:rgbFrame.linesize * pCodecCtx->height];
        rgbFrame.width = pCodecCtx->width;
        rgbFrame.height = pCodecCtx->height;
        UIImage *image = [rgbFrame.asImage copy];
        [self closeScaler];
        return image;
  //  }
    return nil;
}

#pragma mark yuv 转换
- (KxVideoFrame *) handleVideoFrame
{
    if (!pVideoFrame->data[0])
        return nil;
    
    KxVideoFrame *frame;
    
    if (_videoFrameFormat == KxVideoFrameFormatYUV)
    {
        
        KxVideoFrameYUV * yuvFrame = [[KxVideoFrameYUV alloc] init];
        yuvFrame.luma = copyFrameData(pVideoFrame->data[0],
                                         pVideoFrame->linesize[0],
                                         pVideoFrame->width,
                                         pVideoFrame->height);
        yuvFrame.chromaB = copyFrameData(pVideoFrame->data[1],
                                            pVideoFrame->linesize[1],
                                            pVideoFrame->width / 2,
                                            pVideoFrame->height / 2);
        yuvFrame.chromaR = copyFrameData(pVideoFrame->data[2],
                                            pVideoFrame->linesize[2],
                                            pVideoFrame->width / 2,
                                            pVideoFrame->height / 2);
        frame = yuvFrame;
        memcpy(pNewVideoFrame, pVideoFrame, sizeof(AVFrame));
        frame.width = pVideoFrame->width;
        frame.height = pVideoFrame->height;//21+38*x
    }
    else
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
        frame.width = pCodecCtx->width;
        frame.height = pCodecCtx->height;
    }
    frame.duration = 1.0 / _fps;
    pts += frame.duration;
    frame.position = pts;
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
    
    if (_pictureValid) {
        avpicture_free(&_picture);
        _pictureValid = NO;
    }
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

-(void)ptz_control:(int)nPtz
{
    if(recv)
    {
        PtzControlMsg ptzmsg;
        ptzmsg.ptzcmd = (PTZCONTROLTYPE)nPtz;
        ptzmsg.channel = 0;
        recv->sendPtzControl(&ptzmsg);
    }
}

-(void)setTimeOut:(int)nTime
{
    nTimeOut = nTime;
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




