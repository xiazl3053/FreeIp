//
//  XLDecoder.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/13.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "IDecoder.h"
#import "IDecodeSource.h"
@interface XLDecoder : IDecoder

@property (nonatomic,strong) IDecodeSource *decodeSrc;

-(void)decoderInit;
-(NSArray*)decodeFrame;
@end
