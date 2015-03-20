//
//  ISource.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/11.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "IDecodeSource.h"

@implementation IDecodeSource

-(BOOL)connection:(NSString*)strSource
{
    return YES;
}

-(NSData*)getNextFrame
{
    return nil;
}

-(void)sendMessage
{
    
}
-(void)destorySource
{
    
}
@end