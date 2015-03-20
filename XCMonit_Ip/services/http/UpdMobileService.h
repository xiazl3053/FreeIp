//
//  UpdMobileService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/11.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"
typedef void(^HttpUpdMobile)(int nStatus);

@interface UpdMobileService : HttpManager

@property (nonatomic,copy) HttpUpdMobile httpBlock;

-(void)requestUpdMobile:(NSString*)strReal;

@end
