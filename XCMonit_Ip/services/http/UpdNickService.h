//
//  UpdNickService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/11.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^HttpUpdNick)(int nStatus);


@interface UpdNickService : NSObject

@property (nonatomic,copy) HttpUpdNick httpBlock;

-(void)requestUpdNick:(NSString*)strReal;

@end
