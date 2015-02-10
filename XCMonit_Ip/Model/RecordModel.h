//
//  RecordModel.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/30.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordModel : NSObject


@property (nonatomic,assign) NSInteger nId;
@property (nonatomic,assign) NSInteger allTime;
@property (nonatomic,assign) NSInteger nFramesNum;
@property (nonatomic,assign) NSInteger nFrameBit;
@property (nonatomic,strong) NSString *strDevNO;
@property (nonatomic,strong) NSString *strDevName;
@property (nonatomic,strong) NSString *strStartTime;
@property (nonatomic,strong) NSString *strEndTime;
@property (nonatomic,strong) NSString *strFile;
@property (nonatomic,strong) NSString *imgFile;
-(id)initWithItems:(NSArray*)items;

@end
