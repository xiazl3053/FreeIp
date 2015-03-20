//
//  DeviceInfoDb.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-21.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import <Foundation/Foundation.h>

@class DevModel;
@class UserModel;

@interface DeviceInfoDb : NSObject



+(NSArray *)queryAllDevInfo;
+(NSArray *)queryUserInfo;

+(BOOL)insertUserInfo:(UserModel *)user;
+(BOOL)insertDevInfo:(DevModel *)devModel;
+(BOOL)deleteDevInfo:(DevModel*)devModel;
+(BOOL)querySavePwd;
+(BOOL)updateSavePwd:(NSInteger)nSave;
+(BOOL)queryLogin;
+(BOOL)updateLogin:(NSInteger)nLogin;


@end
