//
//  RtspDecoder.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/18.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RtspDecoder.h"
#import "XCNotification.h"
#include <stdio.h>
#import "ProgressHUD.h"
#import "Toast+UIView.h"
#include <sys/time.h>
#import "UtilsMacro.h"
#import "RecordModel.h"
#import "RecordDb.h"
#include <stdio.h>
//#include "private_protocol.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <unistd.h>
#include "LongseDes.h"
#import "RtspInfo.h"
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#import "P2PInitService.h"

extern "C"
{
    #import "DIrectDVR.h"
    #include "libavformat/avformat.h"
    #include "libswscale/swscale.h"
}


#define RTSP_CONNECT_TIME_OUT 10
int rtspConnect_time_out;
void avStreamFPSTimeBaseInfo(AVStream *st, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
{
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.den && st->codec->time_base.num)
        timebase = av_q2d(st->codec->time_base);
    else
        timebase = defaultTimeBase;
    
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

int getNextFrame(void *userData,unsigned char *cFrame,int nLength)
{
    int size = nLength;
    int ret = -1;
    struct timeval tv;
    gettimeofday(&tv,NULL);
    NSMutableArray *aryVideo = (__bridge NSMutableArray *)userData;
    do{
        struct timeval result;
        gettimeofday(&result,NULL);
        if(aryVideo.count>0)
        {
            @synchronized(aryVideo)
            {
                NSData *data = [aryVideo objectAtIndex:0];
                size = (int)data.length;
                memcpy(cFrame, [data bytes], data.length);
                [aryVideo removeObjectAtIndex:0];
                ret = 0;
            }
        }
        if(result.tv_sec-tv.tv_sec>=rtspConnect_time_out)
        {
            DLog(@"退出了");
            return -1;
        }
    }while(ret);
    return size;
}


@interface RtspDecoder()

{
    AVFormatContext     *pFormatCtx;
    AVCodecContext      *pSubtitleCodecCtx;
    AVCodecContext      *pAudioCodecCtx;
    AVCodecContext      *pCodecCtx;
    
    AVFrame             *pVideoFrame;
    AVFrame             *pAudioFrame;
    
    NSDictionary        *_info;
    NSUInteger          _artworkStream,_subtitleASSEvents;
    void *_swrBuffer;
    NSUInteger          _swrBufferSize;
    AVPacket            *_packet;
    CGFloat  pts;
    FILE *file_record;
    size_t file_size;
    int nConnectStatus;
    
    CGFloat _bufferedDuration;
    CGFloat _minDuration;
    CGFloat _maxDuration;
    
    AVPicture picture;
    struct SwsContext *img_convert_ctx;
    int nOutWidth,nOutHeight;
    int _videoStream,_audioStream,_subtitleStream;
    KxVideoFrameFormat  _videoFrameFormat;
    
    BOOL _bIsDecoding;
    NSArray *_videoStreams;
    
    CGFloat             _position;
    CGFloat             _videoTimeBase,_audioTimeBase;
    
    struct SwsContext   *_swsContext;
    AVPicture           _picture;
    BOOL                _pictureValid;
    BOOL    bNotify;
    CGFloat _minBufferedDuration;
    CGFloat _maxBufferedDuration;
    CGFloat _moviePosition;
    
    dispatch_queue_t _dispatch_queue;
    
    CGFloat start,end;
    char cStart[32];
    char cEnd[32];
    char cFileName[512];
    NSString *strFile;
    NSMutableData *data;
    BOOL bRecord;
    NSString *strRtspPath;
    BOOL bOpening;
    BOOL bConnect;
    long lFrameNum;
    pteClient_t *pClient;
    NSMutableArray *_aryVideo;
}
@property (nonatomic,copy) NSString *strRecordPath;
@property (nonatomic,copy) NSString *strDevName;


@end

@implementation RtspDecoder

-(id)init
{
    self = [super init];
    return self;
}

#pragma mark 解码整流程
- (BOOL) openDecoder: (NSString *) path
               error: (NSError **) perror
{
    pFormatCtx = NULL;
    bOpening = NO;
    bConnect = NO;
    strRtspPath = path;
    
    kxMovieError errCode = [self openfile:path];
    if (errCode == kxMovieErrorNone)
    {
        _maxBufferedDuration = 0.01;
        _bIsDecoding = YES;
        _videoFrameFormat = KxVideoFrameFormatRGB;
        pts = 0;
        bNotify = YES;
        return YES;
    }
    else if (errCode != kxMovieErrorNone)
    {
        NSString *errMsg =[DecoderPublic errorMessage:errCode];
        DLog(@"%@, %@", errMsg, path.lastPathComponent);
        if (perror)
            *perror = [DecoderPublic kxmovieError:errCode str:errMsg];
        return NO;
    }
    return  NO;
}

#pragma mark 录像操作 ffmpeg
-(kxMovieError)openfile:(NSString*)strPath
{
    pFormatCtx = NULL;
    _bIsDecoding = NO;
    avcodec_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    AVDictionary* options = NULL;
    av_dict_set(&options, "rtsp_transport", "tcp", 0);
    av_dict_set(&options, "stimeout", "3500000", 0);
    AVCodec *pCodec = NULL;
    @synchronized(self)
    {
       if(avformat_open_input(&pFormatCtx, [strPath UTF8String], NULL, &options) != 0 )
        {
            bOpening = NO;
            goto Release_format_input;
        }
    }

    
    bConnect = YES;
    bOpening = YES;
    pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    pCodecCtx = avcodec_alloc_context3(pCodec);
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        return kxMovieErrorOpenCodec;
    }
    pVideoFrame = avcodec_alloc_frame();
    if( pVideoFrame == NULL )
    {
        return kxMovieErrorOpenCodec;
    }
    _fps = 25;
    DLog(@"fps:%f",_fps);
    return kxMovieErrorNone;
Release_open_input:
    pFormatCtx = NULL;
    return kxMovieErrorOpenFile;
Release_format_input:
    return kxMovieErrorStreamNotFound;
}



-(NSString *)getIPWithHostName:(const NSString *)hostName
{
    NSString *_strAddress;
    const char *hostN= [hostName UTF8String];
    struct hostent* phot;
    @try
    {
        phot = gethostbyname(hostN);
    }
    @catch (NSException *exception)
    {
        return nil;
    }
    struct in_addr ip_addr;
    if(phot)
    {
        memcpy(&ip_addr, phot->h_addr_list[0], 4);
        char ip[20] = {0};
        inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
        _strAddress = [NSString stringWithUTF8String:ip];
        return _strAddress;
    }
    else
    {
        return nil;
    }
}

#pragma mark 私有协议
-(int)protocolInit:(RtspInfo*)rtspInfo path:(NSString *)strPath channel:(int)nChannel code:(int)nCode
{
    int nLogin=0;
    _aryVideo = [NSMutableArray array];
    strRtspPath = strPath;
    @synchronized(self)
    {
        //新加入解析
        NSString *strAddress = [self getIPWithHostName:rtspInfo.strAddress];
        Direct_UserInfo *direct= (Direct_UserInfo*)malloc(sizeof(Direct_UserInfo));
        
        sprintf((char*)direct->userinfo.ucUsername,"%s",[rtspInfo.strUser UTF8String]);
        sprintf((char*)direct->userinfo.ucPassWord, "%s",[rtspInfo.strPwd UTF8String]);
        int rsl = PC_InitCtx();
        if(0!=rsl)
        {
            return DIRECT_CONNECT_INIT_FAIL;
        }
        pClient = PC_CreateNew();
        if(0==pClient)
        {
            return DIRECT_CONNNECT_NEW_FAIL;
        }
        direct->nPort = rtspInfo.nPort;
        if (strAddress)
        {
            sprintf((char*)direct->cAddress,"%s",[strAddress UTF8String]);
        }
        else
        {
            sprintf((char*)direct->cAddress,"%s",[rtspInfo.strAddress UTF8String]);
        }
        nLogin = Direct_Connect(pClient,direct,nCode,nChannel);
    }
    if(nLogin > 0)
    {
        DLog(@"connect Fail:%d",nLogin);
        return 0;
    }
    rtspConnect_time_out = 30;
    
    pClient->aryVideo = (__bridge void*)_aryVideo;
    
    __weak RtspDecoder *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [__self ffmpegInit];
    });
    return 1;
}

#pragma mark 私有协议解码  ffmpeg初始化
-(BOOL)ffmpegInit
{
    bNotify = YES;
    pFormatCtx = NULL;
    _bIsDecoding = NO;
 
    AVInputFormat* pAvinputFmt = NULL;
    AVCodec         *pCodec = NULL;
    AVIOContext		*pb = NULL;
    uint8_t	*buf = NULL;
    buf = (uint8_t*)malloc(sizeof(uint8_t)*1024);
    avcodec_register_all();
    pb = avio_alloc_context(buf, 1024, 0, (__bridge void *)(_aryVideo), getNextFrame,NULL,NULL);
    pAvinputFmt = av_find_input_format("H264");
    pFormatCtx = avformat_alloc_context();
    pFormatCtx->pb = pb;
    @synchronized(self)
    {
        if(avformat_open_input(&pFormatCtx, "", pAvinputFmt, NULL) != 0 )
        {
            pFormatCtx = NULL;
            av_free(pb);
            return NO;
        }
    }
    bConnect = YES;
    bOpening = YES;
    DLog(@"找到视频信息");
    pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    pCodecCtx = avcodec_alloc_context3(pCodec);
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        DLog(@"没有找到视频信息?");
        return NO;
    }
    pVideoFrame = avcodec_alloc_frame();
    if( pVideoFrame == NULL )
    {
        DLog(@"初始化失败?");
        return NO;
    }
    _fps = 25;
    _bIsDecoding = YES;
    return YES;
}

-(void)dealloc
{
    if (bRecord)
    {
        [self stopRecord];
    }
    rtspConnect_time_out = 1;
    DLog(@"rtsp释放");
    [self closeScaler];
    [self closeFile];
}

-(void)closeFile
{
    _videoStream = -1;
    if (pClient)
    {
        destoryClient(pClient);
        DLog(@"stopInfo");
    }
    [_aryVideo removeAllObjects];
    if (pVideoFrame)
    {
        av_free(pVideoFrame);
        pVideoFrame = NULL;
    }
    if (pCodecCtx)
    {
        [[P2PInitService sharedP2PInitService].getTheLock lock];
        avcodec_close(pCodecCtx);
        [[P2PInitService sharedP2PInitService].getTheLock unlock];
        pCodecCtx = NULL;
    }
    if (pFormatCtx)
    {
        avformat_free_context(pFormatCtx);
    }
    DLog(@"avformat_free_context");

}

#pragma mark 视频流操作
- (kxMovieError) openVideoStream
{
    for (int i = 0; i < pFormatCtx->nb_streams;i++)
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
        return kxMovieErrorOpenCodec;
    }
    pCodecCtx = pFormatCtx->streams[_videoStream]->codec;
    AVCodec *pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        return kxMovieErrorOpenCodec;
    }
    pVideoFrame = avcodec_alloc_frame();
    if( pVideoFrame == NULL )
    {
        return kxMovieErrorOpenCodec;
    }
    AVStream *st = pFormatCtx->streams[_videoStream];
    avStreamFPSTimeBaseInfo(st, 0.04, &_fps, &_videoTimeBase);
    if (_fps==0) {
        _fps = 25.0f;
    }
    DLog(@"fps:%f",_fps);
    return kxMovieErrorNone;
}

-(NSArray *)collectStreams:(AVFormatContext *)formatCtx type:(enum AVMediaType)codecType
{
    NSMutableArray *ma = [NSMutableArray array];
    for (NSInteger i = 0; i < formatCtx->nb_streams; ++i)
        if (codecType == formatCtx->streams[i]->codec->codec_type)
            [ma addObject: [NSNumber numberWithInteger: i]];
    return [ma copy];
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
    // determine fps
    AVStream *st = pFormatCtx->streams[_videoStream];
    avStreamFPSTimeBaseInfo(st, 0.04, &_fps, &_videoTimeBase);
    DLog(@"_fps:%f",_fps);
    return kxMovieErrorNone;
}

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
            if(bRecord)
            {
                 [data appendBytes:packet.data length:packet.size];
            }
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
            if(bNotify)
            {
                bNotify = NO;
                DLog(@"丢失连接");
                [[NSNotificationCenter defaultCenter] postNotificationName:NS_RTSP_DISCONNECT_VC object:nil];
            
            }
            break;
        }
    }
    av_free_packet(&packet);
    return result;
}

#pragma mark 处理yuv数据
-(KxVideoFrame *)handleVideoFrame
{
    if (!pVideoFrame->data[0])
        return nil;
    KxVideoFrame *frame;
    if (!_swsContext &&
        ![self setupScaler])
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
    _moviePosition += frame.duration;
    frame.position = _moviePosition;
    return frame;
}

#pragma mark rgb
- (BOOL) setupScaler
{
    [self closeScaler];
    DLog(@"pCodecCtx->height:%d-%d",pCodecCtx->width,pCodecCtx->height);
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

- (NSUInteger) frameWidth
{
    return _bIsDecoding ? pCodecCtx->width : 0;
}

- (NSUInteger) frameHeight
{
    return _bIsDecoding ? pCodecCtx->height : 0;
}


#pragma mark RTSP录像
-(void)recordStart:(NSString*)strPath name:(NSString*)strDevName
{
    start = _moviePosition;
    //  创建文件  获取系统时间  序列号  peerName
    NSDate *senddate=[NSDate date];
    //时间格式
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
    NSString *  morelocationString=[dateformatter stringFromDate:senddate];
    
    //保存文件路径
    NSDateFormatter  *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *filePath = [NSString stringWithFormat:@"%@.mp4",[fileformatter stringFromDate:senddate]];
    
    _strRecordPath = strPath;
    _strDevName = strDevName;
    
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
            DLog(@"Error excluding不备份文件夹");
        }
    }
    //视频文件保存路径
    strFile  = [strDir stringByAppendingPathComponent:filePath];
    //开始时间与文件名
    sprintf(cStart, "%s",[morelocationString UTF8String]);
    sprintf(cFileName,"%s",[filePath UTF8String]);
    DLog(@"strFile:%@",strFile);
    lFrameNum = pCodecCtx->frame_number;
    if ([[NSFileManager defaultManager] createFileAtPath:strFile contents:nil attributes:nil])
    {
        DLog(@"创建文件成功:%@",strFile);
    }
    data = [[NSMutableData alloc] init];
    bRecord = YES;
}

-(void)stopRecord
{
    if (!bRecord)
    {
        return ;
    }
    lFrameNum = pCodecCtx->frame_number-lFrameNum;
    end = _moviePosition;
    if ([data writeToFile:strFile atomically:YES])
    {
        DLog(@"写入成功");
    }
    BOOL success = [[NSURL fileURLWithPath:strFile] setResourceValue: [NSNumber numberWithBool: YES]
                                                              forKey: NSURLIsExcludedFromBackupKey error:nil];
    if(!success)
    {
        DLog(@"Error excluding文件");
    }
    NSDate *senddate=[NSDate date];
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSString *  morelocationString=[dateformatter stringFromDate:senddate];
    DLog(@"结束时间:%@",morelocationString);
    //在数据库中加入纪录
    sprintf(cEnd, "%s",[morelocationString UTF8String]);
    RecordModel *record = [[RecordModel alloc] init];
    NSString *strPathNO = nil;
    if ([strRtspPath rangeOfString:@"trackID"].location != NSNotFound)
    {
        //DVR或者NVR
        const char *cPath = [strRtspPath UTF8String];
        char cAddr[100];
        sscanf(cPath,"rtsp://%[^/]/",cAddr);
        DLog(@"%s",cAddr);
        strPathNO = [NSString stringWithFormat:@"rtsp://%s",cAddr];
    }
    else
    {
        strPathNO = strRtspPath;
    }
    record.strDevNO = strPathNO;
    record.nFramesNum = lFrameNum;
    record.nFrameBit = _fps;
    record.strStartTime = [NSString stringWithUTF8String:cStart];
    record.strEndTime = [NSString stringWithUTF8String:cEnd];
    record.strFile = [NSString stringWithUTF8String:cFileName];
    record.imgFile = _strRecordPath;
    record.strDevName = _strDevName;
    NSDateFormatter *date=[[NSDateFormatter alloc] init];
    [date setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    record.allTime = end-start;
    [RecordDb insertRecord:record];
    bRecord = NO;
    data = nil;
    DLog(@"录像停止");
}

-(void)releaseRtspDecoder

{
    _bExit = YES;
    _playing = NO;
    rtspConnect_time_out = 1;
}

@end
