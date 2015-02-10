//
//  DevModel.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-21.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DevModel : NSObject

@property (nonatomic,assign) NSInteger nId;
@property (nonatomic,strong) NSString *strDevName;
@property (nonatomic,strong) NSString *strDevNO;

-(id)initWithDev:(NSString *)devName devNO:(NSString*)devNO;


@end
