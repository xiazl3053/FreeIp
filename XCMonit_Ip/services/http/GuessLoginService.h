//
//  GuessLoginService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/11/18.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpManager.h"

typedef void(^HttpGuessLogin)(int nstatus);

@interface GuessLoginService : HttpManager

@property (nonatomic,copy) HttpGuessLogin httpGuessBlock;

-(void)connectionHttpLogin;

@end
