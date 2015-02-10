//
//  LoginInfo.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/10.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoginInfo : NSObject


@property (nonatomic,assign) NSInteger nLoginStatus;
@property (nonatomic,strong) NSString* strLogin;
@property (nonatomic,assign) NSInteger nLoginErr;
@property (nonatomic,strong) NSString* strErrInfo;
@property (nonatomic,strong) NSString* strLoginId;

-(id)initWidthItem:(NSArray*)items;

@end