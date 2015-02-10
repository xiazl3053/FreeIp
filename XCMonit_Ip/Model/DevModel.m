//
//  DevModel.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-21.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "DevModel.h"

@implementation DevModel


-(id)initWithDev:(NSString *)devName devNO:(NSString*)devNO
{
    self = [super init];
    if (self) {
        _strDevName  = devName;
        _strDevNO = devNO;
    }
    return self;
}
-(void) dealloc
{
    _strDevName= nil;
    _strDevNO = nil;
}

@end
