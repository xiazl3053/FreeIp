//
//  XCDecoderNew.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DecoderPublic.h"
@interface XCDecoderNew : NSObject


-(void)startConnect:(NSString *)strNo;
-(void)startConnectWithChan:(NSString *)strNo channel:(int)nChannel;

-(void)pauseVideo;
-(void)stopVideo;
-(KxVideoFrame*)getNextFrame;
-(NSMutableArray*)getVideoArray;
-(void)startPlay;
-(void)destorySDK;
-(void)releaseDecode;
-(BOOL)setupVideoFrameFormat: (KxVideoFrameFormat) format;
-(id)initWithFormat:(KxVideoFrameFormat)format;
-(void)recordStart;
-(void)recordStop;
-(void)switchP2PCode:(int)nCode;



@property (nonatomic,strong) NSMutableArray *videoArray;
@property (nonatomic,assign) CGFloat fFPS;
@property (nonatomic,assign) CGFloat frameWidth;
@property (nonatomic,assign) CGFloat frameHeight;
@property (nonatomic,assign) BOOL    bNotify;
@property (nonatomic,strong) NSString *strNO;
@property (nonatomic,assign) int nError;
@property (nonatomic,strong) NSString *strError;
@property (nonatomic,assign) BOOL playing;
@property (nonatomic,assign) NSInteger nTagView;
@property (nonatomic,assign) NSInteger nTagGl;
@property (nonatomic,assign) int nChannel;
@property (nonatomic,assign) BOOL bSwitch;
@end
