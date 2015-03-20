//
//  XCLoginService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/10.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"

@class LoginInfo;
typedef void(^HttpLoginBlock)(LoginInfo *login,int nstatus);

@interface LoginService :HttpManager

@property (nonatomic,copy) NSString *strKey;
@property (nonatomic,copy) HttpLoginBlock httpBlock;

-(void)connectionHttpLogin:(NSString *)strUser pwd:(NSString*)strPwd;

@end
