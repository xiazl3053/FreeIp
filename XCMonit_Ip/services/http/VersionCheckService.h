//
//  VersionCheckService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/4/27.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "HttpManager.h"

typedef void(^HttpVersioCheck)(NSString *strVersion);


@interface VersionCheckService : HttpManager

@property (nonatomic,copy) HttpVersioCheck httpBlock;

-(void)requestVersion;

@end
