//
//  UpdEmailService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/10.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"


typedef void(^HttpUpdEmail)(int nStatus);

@interface UpdEmailService :HttpManager


@property (nonatomic,copy) HttpUpdEmail httpBlock;

-(void)requestUpdEmail:(NSString*)strEmail;

@end
