//
//  DeviceInfoModel.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/11.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceInfoModel : NSObject


@property (nonatomic,strong) NSString *strDevNO;
@property (nonatomic,assign) NSInteger iDevOnline;
@property (nonatomic,assign) NSInteger iDevBind;
@property (nonatomic,strong) NSString *strDevType;
@property (nonatomic,strong) NSString *strDevAuth;
@property (nonatomic,strong) NSString *strDevVersion;
@property (nonatomic,strong) NSString *strDevName;

-(id)initWithItems:(NSArray*)items;


@end
