//  根据邮箱修改密码
//  UpdateForEmailService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/11/14.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UtilsMacro.h"



typedef void(^HttpRequestAuthCode)(int nStatus);
typedef void(^HttpUpdPwdByEmail)(int nStatus);

@interface UpdateForEmailService : NSObject

DEFINE_SINGLETON_FOR_HEADER(UpdateForEmailService);

@property (nonatomic,copy) HttpRequestAuthCode httpAuthCode;
@property (nonatomic,copy) HttpUpdPwdByEmail httpUpdPwd;

/*
    邮箱修改密码请求
    strPwd:用户密码
    strCode:验证码
    触发回调函数
*/
-(void)requestUpdForEmail:(NSString *)strPwd code:(NSString*)strCode;
/*
    通过邮箱获取验证码
    strEmail:用户邮箱
 */
-(void)requestAuthCode:(NSString*)strEmail;



@end
