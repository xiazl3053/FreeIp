//
//  IDecoderService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/11.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDecodeSource.h"
#import "IDecoder.h"

@interface IDecoderService : NSObject
/**
 *  建立码流连接，码流的来源包含P2P方式、RTSP方式、录像方式、私有协议方式
 *
 *  @param source 来源接口
 *
 *  @return YES成功，NO失败
 */
-(BOOL)connection:(IDecodeSource*)source;
/**
 *  解码器初始化
 *
 *  @param decode 解码器接口，目前只有ffmpeg方式
 *
 *  @return YES成功
 */
-(BOOL)decoder_init:(IDecoder*)decode;
/**
 *  解码一帧
 *
 *  @return <#return value description#>
 */
-(NSArray*)decodeFrame;
/**
 *  销毁
 */
-(void)destory;
/**
 *  抓拍
 */
-(void)capture;
/**
 *  录像
 */
-(void)recording;
@end
