//
//  DeleteDevService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/13.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"
typedef void(^HttpDelDev)(int nStatus);
@interface DeleteDevService : HttpManager

@property (nonatomic,copy) HttpDelDev httpDelDevBlock;

-(void)requestDelDevInfo:(NSString*)strDevNO auth:(NSString *)strDevAuth;


@end
