//
//  RegisterAuthCode.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/3.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"
#import "DecodeJson.h"
typedef void(^HttpAuthCode)(NSString *strImg, int nStatus);

typedef void(^HttpAuthRegister)(int nStatus);

typedef void(^HttpAuthUser)(int nStatus);

@interface RegisterAuthCode :HttpManager

@property (nonatomic,copy) HttpAuthRegister httpReg;
@property (nonatomic,copy) HttpAuthCode httpBlock;
@property (nonatomic,copy) HttpAuthUser httpAuthBlock;


-(void)requestAuthCode;
-(void)requestRegister:(NSString*)strUser pwd:(NSString*)strPwd auth:(NSString *)strAuth code:(NSString *)strCode;
-(void)requestAuthUsername:(NSString *)strUser;

@end
