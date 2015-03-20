//
//  XLDecoder.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/13.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//


#import "XLDecoder.h"
#import "IDecodeSource.h"
#import "DecoderPublic.h"

extern "C"
{
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
}

@interface XLDecoder()
{
    AVFrame *pFrame;
    AVPicture _picture;
    struct SwsContext *_swsContext;
    BOOL _pictureValid;
    BOOL bStop;
    AVCodecContext *pCodecCtx;
    CGFloat pts;
}
@end



@implementation XLDecoder


-(void)dealloc
{
    DLog(@"GG");
    [self closeScaler];
    avcodec_free_frame(&pFrame);
    avcodec_close(pCodecCtx);
    _decodeSrc = nil;
}

-(id)initWithDecodeSource:(IDecodeSource *)source
{
    self = [super initWithDecodeSource:source];
    _decodeSrc = source;
    return self;
}
-(void)decoderInit
{
    AVCodec *pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    pCodecCtx = avcodec_alloc_context3(pCodec);
    if(avcodec_open2(pCodecCtx,pCodec, nil))
    {
        DLog(@"error");
    }
    pFrame = avcodec_alloc_frame();
}
-(NSArray*)decodeFrame
{
    NSMutableArray *result = [NSMutableArray array];
    AVPacket packet;
    av_init_packet(&packet);
    int nGot;
    BOOL bFinish=NO;
    while (!bFinish)
    {
        if (bStop)
        {
            DLog(@"从解码器中退出");
            return result;
        }
        NSData *frameData = [_decodeSrc getNextFrame];
        if (frameData)
        {
            packet.size = (int)frameData.length;
            unsigned char* pub = (unsigned char*)malloc(frameData.length);
            memcpy(pub,[frameData bytes],frameData.length);
            packet.data = pub;
            int nTemp = avcodec_decode_video2(pCodecCtx,pFrame,&nGot,&packet);
            if (nGot)
            {
                KxVideoFrame *frame = [self handleVideoFrame];
                if(frame)
                {
                    bFinish = YES;
                   [result addObject:frame];
                }
                if(nTemp==0 || nTemp ==-1)
                {
                    free(pub);
                    frameData = nil;
                    continue;
                }
            }
            free(pub);
        }
        else
        {
            //等待多次没有数据，直接返回
            [NSThread sleepForTimeInterval:0.03f];
        }
        frameData = nil;
    }
    av_free_packet(&packet);
    return result;
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

#pragma mark yuv 转换
- (KxVideoFrame *) handleVideoFrame
{
    if (!pFrame->data[0])
        return nil;
    
    KxVideoFrame *frame;
    //
    //    if (_videoFrameFormat == KxVideoFrameFormatYUV)
    //    {
    //
    //        KxVideoFrameYUV * yuvFrame = [[KxVideoFrameYUV alloc] init];
    //        yuvFrame.luma = copyFrameData(pVideoFrame->data[0],
    //                                         pVideoFrame->linesize[0],
    //                                         pVideoFrame->width,
    //                                         pVideoFrame->height);
    //        yuvFrame.chromaB = copyFrameData(pVideoFrame->data[1],
    //                                            pVideoFrame->linesize[1],
    //                                            pVideoFrame->width / 2,
    //                                            pVideoFrame->height / 2);
    //        yuvFrame.chromaR = copyFrameData(pVideoFrame->data[2],
    //                                            pVideoFrame->linesize[2],
    //                                            pVideoFrame->width / 2,
    //                                            pVideoFrame->height / 2);
    //        frame = yuvFrame;
    //        memcpy(pNewVideoFrame, pVideoFrame, sizeof(AVFrame));
    //        frame.width = pVideoFrame->width;
    //        frame.height = pVideoFrame->height;
    //    }
    //    else
    //    {
    
    if (!_swsContext && ![self setupScaler])
    {
        DLog(@"fail setup video scaler");
        return nil;
    }
    sws_scale(_swsContext,
              (const uint8_t **)pFrame->data,
              pFrame->linesize,
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
    //    }
    frame.duration = 1.0 / 25;
    pts += frame.duration;
    frame.position = pts;
    return frame;
}

-(void)stopDecode
{
    bStop = YES;
}

@end
