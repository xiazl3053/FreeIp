//
//  DecoderPublic.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * kxmovieErrorDomain;
typedef enum {
    
    kxMovieErrorNone,
    kxMovieErrorOpenFile,
    kxMovieErrorStreamInfoNotFound,
    kxMovieErrorStreamNotFound,
    kxMovieErrorCodecNotFound,
    kxMovieErrorOpenCodec,
    kxMovieErrorAllocateFrame,
    kxMovieErroSetupScaler,
    kxMovieErroReSampler,
    kxMovieErroUnsupported,
    
} kxMovieError;

typedef enum {
    
    KxMovieFrameTypeAudio,
    KxMovieFrameTypeVideo,
    KxMovieFrameTypeArtwork,
    KxMovieFrameTypeSubtitle,
    
} KxMovieFrameType;

typedef enum {
    KxVideoFrameFormatRGB,
    KxVideoFrameFormatYUV,
    
} KxVideoFrameFormat;


#define CURRENT_DISPLAY    KxVideoFrameFormatYUV


@interface KxMovieFrame : NSObject
@property (nonatomic) KxMovieFrameType type;
@property (nonatomic) CGFloat position;
@property (nonatomic) CGFloat duration;
@end

@interface KxAudioFrame : KxMovieFrame
@property (nonatomic, strong) NSData *samples;
@end

@interface KxVideoFrame : KxMovieFrame
@property (nonatomic) KxVideoFrameFormat format;
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@end

@interface KxVideoFrameRGB : KxVideoFrame
@property (nonatomic) NSUInteger linesize;
@property (nonatomic, strong) NSData *rgb;
- (UIImage *) asImage;
@end

@interface KxVideoFrameYUV : KxVideoFrame
@property (nonatomic, strong) NSData *luma;
@property (nonatomic, strong) NSData *chromaB;
@property (nonatomic, strong) NSData *chromaR;
@end

@interface KxArtworkFrame : KxMovieFrame
@property (nonatomic, strong) NSData *picture;
- (UIImage *) asImage;
@end

@interface KxSubtitleFrame : KxMovieFrame
@property (nonatomic, strong) NSString *text;
@end


@interface DecoderPublic : NSObject

+(NSString*)errorMessage:(kxMovieError)errorCode;
+(NSError*)kxmovieError:(NSInteger)code str:(id)info;


@end

