//
//  GetSnService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/7/20.
//  Copyright © 2015年 夏钟林. All rights reserved.
//

#import "HttpManager.h"


typedef void(^HttpGetSnInfo)(int nStatus,int nAll);

@interface GetSnService : HttpManager

@property (nonatomic,copy) HttpGetSnInfo getSnInfo;


-(void)requestSn:(NSString *)strDevice;

@end
