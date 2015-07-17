//
//  CloudDecode.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/27.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RecordBlockCloud)(int nStatus,NSArray *aryInfo);

@interface CloudDecode : NSObject

@property (nonatomic,assign) CGFloat fps;
@property (nonatomic,copy) NSString *strTime;
@property (nonatomic,copy) RecordBlockCloud cloudBlock;

-(id)initWithCloud:(NSString*)strNo channel:(int)nChannel codeType:(int)nCode;

-(NSMutableArray*)getCloudInfo:(NSDate*)dateTime;

-(BOOL)playDeviceCloud:(NSDate*)dateTime;

-(BOOL)startVideo:(long)lTime;

-(void)checkView:(NSString *)strTime;

-(NSArray*)decodeFrame;

-(void)stopDecode;

-(void)pauseVideo;

-(void)regainVideo;

-(void)dragTime:(long)lTime;

-(void)startRecord:(NSString *)strPath devName:(NSString *)strDevName;
-(void)stopRecord;


@end
