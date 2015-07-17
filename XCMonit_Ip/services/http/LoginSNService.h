//
//  LoginSNService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/7/17.
//  Copyright © 2015年 夏钟林. All rights reserved.
//

#import "HttpManager.h"

typedef void(^SN_HttpLogin)(int nStatus);


@interface LoginSNService : HttpManager

@property (nonatomic,copy) SN_HttpLogin sn_login;

-(void)requestLoginSN:(NSString *)strUser pwd:(NSString *)strPwd sn:(NSString *)strSN;

@end
