//
//  IDecoderService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/11.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "IDecoderService.h"

@implementation IDecoderService

-(BOOL)connection:(IDecodeSource*)source
{
    return YES;
}

-(BOOL)decoder_init:(IDecoder*)decode
{
    return YES;
}

-(NSArray*)decodeFrame
{
    return nil;
}

-(void)destory
{
    
}

-(void)capture
{
    
}

-(void)recording
{
    
}

@end
