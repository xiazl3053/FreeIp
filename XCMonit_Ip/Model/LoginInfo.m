//
//  LoginInfo.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/10.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "LoginInfo.h"

@implementation LoginInfo

-(id)initWidthItem:(NSArray*)items
{
    self = [super init];
    if (self) {
        _nLoginStatus = [items[0] integerValue];
        _strLogin = items[1];
        _nLoginErr = [items[2] integerValue];
        _strErrInfo = items[3];
        _strLoginId = items[4];
        return self;
    }
    return nil;
}

-(void)dealloc
{
    _strLoginId = nil;
    _strLogin = nil;
    _strErrInfo = nil;
}

@end
