//
//  RtspDecoder.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/18.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "DecoderPublic.h"

@interface RtspDecoder : NSObject

@property (readonly, nonatomic) CGFloat fps;
@property (nonatomic,assign) BOOL isEOF;
@property (nonatomic,assign) BOOL     decoding;
@property (nonatomic,assign) BOOL playing;
@property (nonatomic,strong) NSMutableArray *videoArray;

- (BOOL) openDecoder: (NSString *) path
               error: (NSError **) perror;

-(NSMutableArray*)decodeFrames;

-(NSMutableArray*)getVideoArray;

-(void)startPlay;
-(void)stopRecord;
-(void)startRecord;


@property (readonly, nonatomic) NSUInteger frameWidth;
@property (readonly, nonatomic) NSUInteger frameHeight;
@end
