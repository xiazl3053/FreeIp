//
//  UpdNameService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/20.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"


typedef void(^HttpUpdDev)(int nStatus);
@interface UpdNameService :HttpManager

@property (nonatomic,copy) HttpUpdDev httpBlock;



-(void)requestUpdName:(NSString*)strDevNO name:(NSString *)strDevName;

@end
