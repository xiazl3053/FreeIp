//
//  LoginUserDB.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/18.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UserModel;
@interface LoginUserDB : NSObject


+(BOOL)addLoginUser:(UserModel*)userModel;


@end
