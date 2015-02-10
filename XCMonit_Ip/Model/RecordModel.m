//
//  RecordModel.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/30.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RecordModel.h"

@implementation RecordModel



-(id)initWithItems:(NSArray*)items
{
    self = [super init];
    _nId = [items[0] integerValue];
    _strDevNO = items[1];
    _strStartTime = items[2];
    _strEndTime = items[3];
    _strFile = items[4];
    _allTime = [items[5] integerValue];
    return self;
}

@end
