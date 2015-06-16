//
//  CloudDecode.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/27.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudDecode : NSObject

@property (nonatomic,assign) CGFloat fps;
@property (nonatomic,copy) NSString *strTime;

-(id)initWithCloud:(NSString*)strNo channel:(int)nChannel codeType:(int)nCode;

-(NSMutableArray*)getCloudInfo:(NSDate*)dateTime;

-(BOOL)playDeviceCloud:(NSDate*)dateTime;

-(BOOL)startVideo:(NSString *)strTime;

-(void)checkView:(NSString *)strTime;

-(NSArray*)decodeFrame;

-(void)stopDecode;

-(void)pauseVideo;

@end
