//
//  UserInfoService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"
#import "UserAllInfoModel.h"

typedef void(^HttpUserinfo)(UserAllInfoModel *user,int nStatus);
@interface UserInfoService :HttpManager

@property (nonatomic,copy) HttpUserinfo httpBlock;

-(void)requestUserInfo;

@end
