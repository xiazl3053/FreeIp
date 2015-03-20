//
//  UpdPwdService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/10.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"
typedef void(^HttpUpdPwd)(int nStatus);

@interface UpdPwdService : HttpManager

@property (nonatomic,copy) HttpUpdPwd httpBlock;

-(void)requestUpdPwd:(NSString*)strNewPwd old:(NSString *)strOldPwd;

@end
