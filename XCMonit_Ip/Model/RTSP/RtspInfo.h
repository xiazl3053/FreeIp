//
//  RtspInfo.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RtspInfo : NSObject


@property (nonatomic,assign) NSInteger nId;
@property (nonatomic,strong) NSString *strDevName;
@property (nonatomic,strong) NSString *strUser;
@property (nonatomic,strong) NSString *strPwd;
@property (nonatomic,strong) NSString *strAddress;
@property (nonatomic,assign) NSInteger nPort;
@property (nonatomic,strong) NSString *strType;
@property (nonatomic,assign) NSInteger nChannel;
@property (nonatomic,assign) NSInteger nRow;

-(id)initWithItems:(NSArray*)items;

@end
