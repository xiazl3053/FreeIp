//
//  DecoderPublic.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "DecoderPublic.h"
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#import <Accelerate/Accelerate.h>
#import "KxAudioManager.h"
using namespace std;

extern "C"
{
#include "libswresample/swresample.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
}

typedef const struct __CFData * CFDataRef;
NSString * kxmovieErrorDomain = @"ru.kolyvan.kxmovie";
bool bIsCodeNeedExit;



@implementation KxMovieFrame
@end

@implementation KxAudioFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeAudio; }
@end

@interface KxVideoFrame()

@end

@implementation KxVideoFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeVideo; }
@end

@interface KxVideoFrameRGB ()

@end

@implementation KxVideoFrameRGB
- (KxVideoFrameFormat) format { return KxVideoFrameFormatRGB; }
- (UIImage *) asImage
{
    UIImage *image = nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_rgb));
    if (provider) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace) {
            CGImageRef imageRef = CGImageCreate(self.width,
                                                self.height,
                                                8,
                                                24,
                                                self.linesize,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault,
                                                provider,
                                                NULL,
                                                YES, // NO
                                                kCGRenderingIntentDefault);
            
            if (imageRef) {
                image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            CGColorSpaceRelease(colorSpace);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
}
@end



@implementation KxVideoFrameYUV
- (KxVideoFrameFormat) format { return KxVideoFrameFormatYUV; }
-(void)dealloc
{
    _luma = nil;
    _chromaB = nil;
    _chromaR = nil;
}
@end

@implementation KxArtworkFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeArtwork; }
- (UIImage *) asImage
{
    UIImage *image = nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_picture));
    if (provider) {
        
        CGImageRef imageRef = CGImageCreateWithJPEGDataProvider(provider,
                                                                NULL,
                                                                YES,
                                                                kCGRenderingIntentDefault);
        if (imageRef) {
            
            image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
    
}
@end


@implementation KxSubtitleFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeSubtitle; }
@end


@implementation DecoderPublic

+(NSString*)errorMessage:(kxMovieError)errorCode
{
    switch (errorCode)
    {
        case kxMovieErrorNone:
            return @"";
            
        case kxMovieErrorOpenFile:
            return NSLocalizedString(@"Unable to open file", nil);
            
        case kxMovieErrorStreamInfoNotFound:
            return NSLocalizedString(@"Unable to find stream information", nil);
            
        case kxMovieErrorStreamNotFound:
            return NSLocalizedString(@"Unable to find stream", nil);
            
        case kxMovieErrorCodecNotFound:
            return NSLocalizedString(@"Unable to find codec", nil);
            
        case kxMovieErrorOpenCodec:
            return NSLocalizedString(@"Unable to open codec", nil);
            
        case kxMovieErrorAllocateFrame:
            return NSLocalizedString(@"Unable to allocate frame", nil);
            
        case kxMovieErroSetupScaler:
            return NSLocalizedString(@"Unable to setup scaler", nil);
            
        case kxMovieErroReSampler:
            return NSLocalizedString(@"Unable to setup resampler", nil);
            
        case kxMovieErroUnsupported:
            return NSLocalizedString(@"The ability is not supported", nil);
    }
    return nil;
}
+(NSError*)kxmovieError:(NSInteger)code str:(id)info
{
    NSDictionary *userInfo = nil;
    
    if ([info isKindOfClass: [NSDictionary class]]) {
        
        userInfo = info;
        
    } else if ([info isKindOfClass: [NSString class]]) {
        
        userInfo = @{ NSLocalizedDescriptionKey : info };
    }
    
    return [NSError errorWithDomain:kxmovieErrorDomain
                               code:code
                           userInfo:userInfo];
}

@end




