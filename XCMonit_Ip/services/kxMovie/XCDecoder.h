//
//  XCDecoder.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-13.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "DecoderPublic.h"

@interface XCDecoder : NSObject

typedef BOOL(^KxMovieDecoderInterruptCallback)();

typedef int (^XCReadData)(void *opaque, uint8_t *buf, int buf_size);

@property (readonly, nonatomic, strong) NSString *path;
@property (readonly, nonatomic) NSUInteger frameWidth;
@property (readonly, nonatomic) NSUInteger frameHeight;
@property (nonatomic,copy)UIImage *imgPlay;
@property (readwrite, nonatomic) BOOL disableDeinterlacing;
@property (readonly) BOOL isEOF;
@property (readonly) BOOL bIsDecoding;
@property (nonatomic,copy) XCReadData xcRead;
@property (readonly, nonatomic) CGFloat fps;
@property (nonatomic, copy) KxMovieDecoderInterruptCallback interruptCallback;
@property (readonly, nonatomic) BOOL isNetwork;
@property (readonly, nonatomic) CGFloat startTime;
@property (readwrite,nonatomic) CGFloat position;
@property (readwrite, nonatomic) CGFloat duration;
@property (nonatomic,assign) CGFloat allTime;
@property (nonatomic,assign) BOOL nSwitchcode;


-(id)initWithNO:(NSString *)strNO format:(NSUInteger)nFormat;
-(BOOL)setupVideoFrameFormat:(KxVideoFrameFormat) format;
-(NSMutableArray*)decodeFrames;
-(void)clearDuration:(CGFloat)duration;
-(BOOL)getExit;
-(void)destorySDK;
-(void)releaseDecode;
-(void)recordStart;
-(void)recordStop;

-(id)initWithPath:(NSString*)strPath;
- (BOOL) openDecoder: (NSString *) path
               error: (NSError **) perror;


-(KxVideoFrame*)getNextFrame;
-(NSMutableArray*)getVideoArray;
-(void)startPlay;

-(void)switchP2PCode:(int)nCode;

@end
