//
//  CaptureService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/23.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UtilsMacro.h"
@interface CaptureService : NSObject

DEFINE_SINGLETON_FOR_HEADER(CaptureService);


//yuv抓拍方式
+(BOOL)captureToPhotoYUV:(UIImage *)image name:(NSString*)devName;// width:(CGFloat)fWidth height:(CGFloat)fHeight;
+(NSString*)captrueRecordYUV:(UIImage *)image;
//RGB抓拍方式
+(BOOL)captureToPhotoRGB:(UIImageView *)imageView devName:(NSString *)strDevName;
+(NSString*)captureRecordRGB:(UIImageView*)imageView;

@end
