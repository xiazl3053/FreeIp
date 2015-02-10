//
//  DeviceInfoModel.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/11.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "DeviceInfoModel.h"

@implementation DeviceInfoModel

-(id)initWithItems:(NSArray*)items
{
    self = [super init];
    if(self)
    {
        _strDevNO = items[0];
        _iDevOnline = [items[1] integerValue];
        _iDevBind = [items[2] integerValue];
        _strDevType = items[3];
        _strDevVersion = items[4];
        _strDevAuth = items[5];
        _strDevName = items[6];
    }
    return self;
}

@end
