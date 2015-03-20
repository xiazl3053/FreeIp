//
//  DeviceService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/11.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"

@class HttpManager;
@class DeviceInfoModel;

typedef void (^HttpDeviceBlock)(DeviceInfoModel *devInfo,NSInteger nCount);

@interface DeviceService : HttpManager

@property (nonatomic,copy) HttpDeviceBlock httpDeviceBlock;


-(void)requestDeviceLimit:(int)nIndex count:(int)nCount;
-(void)queryDeviceNumber;
@end
