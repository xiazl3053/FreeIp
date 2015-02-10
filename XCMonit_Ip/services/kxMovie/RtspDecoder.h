//
//  RtspDecoder.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/18.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "DecoderPublic.h"

@class RtspInfo;
@interface RtspDecoder : NSObject

@property (readonly, nonatomic) CGFloat fps;
@property (nonatomic,assign) BOOL isEOF;
@property (nonatomic,assign) BOOL     decoding;
@property (nonatomic,assign) BOOL playing;

@property (nonatomic,assign) NSInteger nTimeOut;

-(BOOL)openDecoder:(NSString *)path error:(NSError **) perror;

-(NSMutableArray*)decodeFrames;

-(void)stopRecord;//录像结束
-(void)recordStart:(NSString*)strPath name:(NSString*)strDevName;//录像开始
-(int)protocolInit:(RtspInfo*)rtspInfo path:(NSString *)strPath channel:(int)nChannel code:(int)nCode;//DVR直连
-(void)releaseRtspDecoder;//释放rtsp一些标志


@property (nonatomic, assign) BOOL bExit;
@property (readonly, nonatomic) NSUInteger frameWidth;
@property (readonly, nonatomic) NSUInteger frameHeight;
@end
