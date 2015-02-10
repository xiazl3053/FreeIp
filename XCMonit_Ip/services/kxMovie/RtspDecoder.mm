//
//  RtspDecoder.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/18.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RtspDecoder.h"
#import "XCNotification.h"
#import "ProgressHUD.h"
#import "Toast+UIView.h"
#include "libswresample/swresample.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#import "UtilsMacro.h"
#import "RecordModel.h"
#import "RecordDb.h"

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
}

@end


@implementation RtspDecoder





#pragma mark 解码整流程
- (BOOL) openDecoder: (NSString *) path
               error: (NSError **) perror
{
    pFormatCtx = NULL;
    DLog(@"path:%@",path);
    strRtspPath = path;
    kxMovieError errCode = [self openfile:path];
    if (errCode == kxMovieErrorNone)
    {
        kxMovieError videoErr = [self openVideoStream];
        if (videoErr != kxMovieErrorNone)
        {
            errCode = videoErr;
        }
    }
    _maxBufferedDuration = 0.01;
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
    _videoFrameFormat = KxVideoFrameFormatRGB;
    _videoArray = [[NSMutableArray alloc] init];
    pts = 0;
    bNotify = YES;
    return YES;
}

#pragma mark 录像操作 ffmpeg
-(kxMovieError)openfile:(NSString*)strPath
{
    pFormatCtx = NULL;
    _bIsDecoding = NO;
    
    av_register_all();
    avcodec_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    AVDictionary* options = NULL;
    av_dict_set(&options, "rtsp_transport", "tcp", 0);
    if(avformat_open_input(&pFormatCtx, [strPath UTF8String], NULL, &options) != 0 )
    {
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

#pragma mark 视频流操作
- (kxMovieError) openVideoStream
{
    kxMovieError errCode = kxMovieErrorStreamNotFound;
    _videoStream = -1;
    _artworkStream = -1;
    _videoStreams = [self collectStreams:pFormatCtx type:AVMEDIA_TYPE_VIDEO];
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
    _videoStream = videoStream;
    
    // determine fps
    AVStream *st = pFormatCtx->streams[_videoStream];
    avStreamFPSTimeBaseInfo(st, 0.04, &_fps, &_videoTimeBase);
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
            [data appendBytes:packet.data length:packet.size];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:NS_RTSP_DISCONNECT_VC object:nil];
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

#pragma mark  play函数
-(void)startPlay
{
    DLog(@"开启播放");
    _dispatch_queue = dispatch_queue_create("com.xzl.newdecode", DISPATCH_QUEUE_CONCURRENT);
    _decoding = NO;
    _playing = YES;
    __weak RtspDecoder *__weakSelf = self;
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
    
    float nTime = _fps;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0/nTime * NSEC_PER_SEC);
    __weak RtspDecoder *weakSelf = self;
    dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
    {
       [weakSelf tick];
    });
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

-(NSMutableArray*)getVideoArray
{
    return _videoArray;
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
-(void)startRecord
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
    bRecord = YES;
}

-(void)stopRecord
{
    if (!bRecord)
    {
        return ;
    }
    end = _moviePosition;
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
    record.strDevNO = strRtspPath;
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
@end
