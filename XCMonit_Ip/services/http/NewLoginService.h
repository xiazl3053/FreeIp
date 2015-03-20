//
//  NewLoginService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/6.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "HttpManager.h"
@class LoginInfo;
typedef void(^HttpLoginBlock)(LoginInfo *login,int nstatus);

@interface NewLoginService : HttpManager
@property (nonatomic,copy) HttpLoginBlock httpBlock;
-(void)requestLogin:(NSString *)strUser pwd:(NSString *)strPassword;

@end
