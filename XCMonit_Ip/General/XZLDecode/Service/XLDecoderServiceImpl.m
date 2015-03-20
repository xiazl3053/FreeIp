//
//  XLDecoderServiceImpl.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/11.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "XLDecoderServiceImpl.h"
#import "DecoderPublic.h"
#import "IDecoder.h"
#import "IDecodeSource.h"


@interface XLDecoderServiceImpl()
{
    
}

@property (nonatomic,strong) IDecoder *decoder;
@property (nonatomic,strong) IDecodeSource *source;
@end

@implementation XLDecoderServiceImpl

-(void)dealloc
{
    _source = nil;
    _decoder = nil;
    DLog(@"释放Decoder");
}
/**
 *  建立码流连接，码流的来源包含P2P方式、RTSP方式、录像方式、私有协议方式
 *
 *  @param source 来源接口
 *
 *  调用时，需要开启一个block
 *  @return YES成功，NO失败
*/
-(BOOL)connection:(IDecodeSource *)source
{
    if (source)
    {
        _source = source;
        BOOL bSource = [_source connection:@"test"];
        if (bSource)
        {
            return YES;
        }
    }
    return  NO;
}
/**
 *  解码器初始化
 *
 *  @param decode 解码器接口，目前只有ffmpeg方式
 *
 *  @return YES成功
 */
-(BOOL)decoder_init:(IDecoder *)decode
{
    if (decode)
    {
        _decoder = decode;
        [_decoder decoderInit];
    }
    return YES;
}
//销毁
-(void)destory
{
    _decoder = nil;
    DLog(@"释放decoder");
}

//抓拍


-(void)capture
{
    
}

//录像
-(void)recording
{
    
}
/**
 *  解码一帧
 *
 *  @return return value description
 */
-(NSArray*)decodeFrame
{
    NSArray *array = [_decoder decodeFrame];
    return array;
}
@end

