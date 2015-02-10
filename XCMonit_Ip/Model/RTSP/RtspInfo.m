//
//  RtspInfo.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RtspInfo.h"

@implementation RtspInfo

-(id)initWithItems:(NSArray*)items
{
    self = [super init];
    if (self) {
        _nId = [items[0] integerValue];
        _strDevName = items[1];
        _strAddress = items[2];
        _nPort = [items[3] integerValue];
        _strUser = items[4];
        _strPwd = items[5];
        _strType = items[6];
        _nChannel = [items[7] integerValue];
        return self;
    }
    return nil;
}


@end
