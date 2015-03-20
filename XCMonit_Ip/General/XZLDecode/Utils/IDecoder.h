//
//  IDecoder.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/11.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDecodeSource.h"
@interface IDecoder : NSObject

-(id)initWithDecodeSource:(IDecodeSource*)source;

-(void)decoderInit;
-(NSArray*)decodeFrame;
-(void)stopDecode;

@end
