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
        /*
         [rs stringForColumn:@"id"],[rs stringForColumn:@"devName"],[rs stringForColumn:@"user"],
         [rs stringForColumn:@"pwd"],[rs stringForColumn:@"address"],[rs stringForColumn:@"port"],
         [rs stringForColumn:@"type"],[rs stringForColumn:@"channel"],nil];
         
         */
        _nId = [items[0] integerValue];
        _strDevName = items[1];
        _strAddress = items[4];
        _nPort = [items[5] integerValue];
        _strUser = items[2];
        _strPwd = items[3];
        _strType = items[6];
        _nChannel = [items[7] integerValue];
        return self;
    }
    return nil;
}


@end
