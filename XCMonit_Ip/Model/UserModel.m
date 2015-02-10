//
//  UserModel.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-21.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "UserModel.h"

@implementation UserModel


-(id)initWithUser:(NSString *)user pwd:(NSString*)pwd
{
    self = [super init];
    if(self)
    {
       _strUser = [user copy];
       _strPwd = [pwd copy];
    }
    return  self;
}
-(void) dealloc
{
    _strPwd = nil;
    _strUser = nil;
}


@end
