//
//  CaptureService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/23.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "CaptureService.h"
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation CaptureService

DEFINE_SINGLETON_FOR_CLASS(CaptureService);

+(UIImage *)glToUIImage:(UIView *)glView
{
    NSInteger width = glView.frame.size.width;
    NSInteger height = glView.frame.size.height;
    NSInteger myDataLength = width * height * 4;
    
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    for(int y = 0; y <height; y++)
    {
        for(int x = 0; x <width * 4; x++)
        {
            buffer2[(height-1 - y) * width * 4 + x] = buffer[y * 4 * width + x];
        }
    }
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2, myDataLength, NULL);
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef];
    return myImage;
}

+(BOOL)captureToPhotoAlbum:(UIView *)_glView
{
    UIImage *image = [CaptureService glToUIImage:_glView];//修改方式
    
    NSDate *senddate=[NSDate date];
    
    //创建一个目录  //shoto
    NSString *strDir = [kLibraryPath stringByAppendingPathComponent:@"shoto"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:strDir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDir withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDir] setResourceValue: [NSNumber numberWithBool: YES]
                                                  forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd"];
    //每天的记录创建一个
    NSString *strDirYear = [strDir stringByAppendingPathComponent:[fileformatter stringFromDate:senddate]];
    DLog(@"strDirYear:%@",strDirYear);
    [fileformatter setDateFormat:@"YYYYMMddHHmmss"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:strDirYear]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDirYear withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDirYear] setResourceValue: [NSNumber numberWithBool: YES]
                                                      forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[fileformatter stringFromDate:senddate]];
    NSString *strPath = [strDirYear stringByAppendingPathComponent:fileName];
    
    BOOL result = [UIImageJPEGRepresentation(image,0.8f) writeToFile:strPath atomically:YES];
    
    BOOL success = [[NSURL fileURLWithPath:strPath] setResourceValue: [NSNumber numberWithBool: YES]
                                                              forKey: NSURLIsExcludedFromBackupKey error:nil];
    if (result&&success)
    {
        return  YES;
    }
    else
    {
        return NO;
    }
}

@end
