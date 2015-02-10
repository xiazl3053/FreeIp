//
//  UserAllInfoModel.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "UserAllInfoModel.h"

@implementation UserAllInfoModel


-(id)initWithItems:(NSArray *)items
{
    self = [super init];
    _strMobile = items[0];
    _strEmail = items[1];//items[2] 邮件是否绑定
    _strName = items[3];
    _strLastInfo = items[5];
    _strFile = items[6];
    _iProNumber = [items[7] integerValue];
    _iCountNumber = [items[8] integerValue];
    return self;
}

@end
