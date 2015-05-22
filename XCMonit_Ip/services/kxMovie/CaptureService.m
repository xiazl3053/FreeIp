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
#import "Picture.h"
#import "PhoneDb.h"
@implementation CaptureService

DEFINE_SINGLETON_FOR_CLASS(CaptureService);

+(UIImage *)glToUIImage:(UIView *)glView //width:(CGFloat)sourceWidth height:(CGFloat)sourceHeight
{
    NSInteger width = glView.frame.size.width;
    NSInteger height = glView.frame.size.height;
    NSInteger myDataLength = width * height * 4;
    
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    
    glReadPixels(0, 0, (int)width, (int)height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
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
    int bytesPerRow = (int)(4 * width);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef];
    return myImage;
}

+(NSString*)capturePhone:(NSString*)strType
{
    NSString *strDir = [kLibraryPath stringByAppendingPathComponent:strType];
    NSDate *senddate=[NSDate date];
    //创建一个目录  //shoto
    if(![[NSFileManager defaultManager] fileExistsAtPath:strDir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDir withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDir] setResourceValue: [NSNumber numberWithBool: YES]
                                                  forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd"];
    NSString *strDirYear = [strDir stringByAppendingPathComponent:[fileformatter stringFromDate:senddate]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:strDirYear])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDirYear withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDirYear] setResourceValue: [NSNumber numberWithBool: YES]
                                                      forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    return strDir;
}


+(NSString*)captrueRecordYUV:(UIImage *)image
{
    NSDate *senddate=[NSDate date];
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd"];
    NSString *strDir = [CaptureService capturePhone:@"record"];
    NSString *strDirYear = [fileformatter stringFromDate:senddate];//年月日
    
    [fileformatter setDateFormat:@"HHmmss"];//时分秒
    
    NSString *fileName = [strDirYear stringByAppendingPathComponent:
            [NSString stringWithFormat:@"%@.jpg",[fileformatter stringFromDate:senddate]]];
    NSString *strPath = [strDir stringByAppendingPathComponent:fileName];
    
    [UIImageJPEGRepresentation(image,1.0f) writeToFile:strPath atomically:YES];
    [[NSURL fileURLWithPath:strPath] setResourceValue: [NSNumber numberWithBool: YES]
                                                              forKey: NSURLIsExcludedFromBackupKey error:nil];
    return fileName;
}
//+(BOOL)captureToPhotoYUV:(UIView *)_glView name:(NSString*)devName width:(CGFloat)fWidth height:(CGFloat)fHeight;
+(BOOL)captureToPhotoYUV:(UIImage *)image name:(NSString*)devName // width:(CGFloat)fWidth height:(CGFloat)fHeight
{
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd"];
    //每天的记录创建一个
    PictureModel *picture = [[PictureModel alloc] init];
    NSDate *senddate=[NSDate date];
    picture.strTime = [fileformatter stringFromDate:senddate];//先创建年月日记录
    NSString *strDir = [CaptureService capturePhone:@"shoto"];//整体目录

    NSString *strDirYear = [strDir stringByAppendingPathComponent:[fileformatter stringFromDate:senddate]];//年月日
    
    [fileformatter setDateFormat:@"HHmmss"];//时分秒

    NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[fileformatter stringFromDate:senddate]];
    NSString *strPath = [strDirYear stringByAppendingPathComponent:fileName];
    
    BOOL result = [UIImageJPEGRepresentation(image,1.0f) writeToFile:strPath atomically:YES];
    BOOL success = [[NSURL fileURLWithPath:strPath] setResourceValue: [NSNumber numberWithBool: YES]
                                                              forKey: NSURLIsExcludedFromBackupKey error:nil];
    picture.strFile = fileName;
    picture.strDevName = devName;
    
    if (result&&success)
    {
        [PhoneDb insertRecord:picture];
        return  YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark 新加入
+(BOOL)captureToPhotoRGB:(UIImageView *)imageView devName:(NSString *)strDevName
{
    UIImage *image = imageView.image;//修改方式
    
    PictureModel *picture = [[PictureModel alloc] init];//数据库model记录
    
    NSDate *senddate=[NSDate date];
    
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd"];//年月日格式
    
    picture.strTime = [fileformatter stringFromDate:senddate];//先创建年月日记录
    
    NSString *strDir = [self capturePhone:@"shoto"];//Library路径
    
    NSString *strDirYear = [strDir stringByAppendingPathComponent:[fileformatter stringFromDate:senddate]];//Library与年月日格式组合
    
    [fileformatter setDateFormat:@"HHmmss"];//时分秒格式
    
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[fileformatter stringFromDate:senddate]];//时分秒的时间格式,数据库中保存成文件
    
    NSString *strPath = [strDirYear stringByAppendingPathComponent:fileName];//整体路径整合
    
    BOOL result = [UIImageJPEGRepresentation(image,1.0f) writeToFile:strPath atomically:YES];
    BOOL success = [[NSURL fileURLWithPath:strPath] setResourceValue: [NSNumber numberWithBool: YES]
                                                              forKey: NSURLIsExcludedFromBackupKey error:nil];
    picture.strFile = fileName;//记录文件名
    picture.strDevName = strDevName;//记录设备名
    if (result&&success)
    {
        [PhoneDb insertRecord:picture];
        return  YES;
    }
    else
    {
        return NO;
    }
}

+(NSString*)captureRecordRGB:(UIImageView*)imageView
{
    UIImage *image = imageView.image;
    NSDate *senddate=[NSDate date];
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    
    [fileformatter setDateFormat:@"YYYY-MM-dd"];//年月日格式
    
    NSString *strDir = [self capturePhone:@"record"];//检测是否有文件，如果没有则创建一个
    
    NSString *strDirYear = [fileformatter stringFromDate:senddate];//字符串年月日
    
    [fileformatter setDateFormat:@"HHmmss"];//时分秒格式
    
    NSString *fileName = [strDirYear stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@.jpg",[fileformatter stringFromDate:senddate]]];//生成年－月－日/时分秒.jpg的格式
    
    NSString *strPath = [strDir stringByAppendingPathComponent:fileName];//与Library路径组合
    
    [UIImageJPEGRepresentation(image,1.0f) writeToFile:strPath atomically:YES];//将图片数据写入路径
    
    [[NSURL fileURLWithPath:strPath] setResourceValue: [NSNumber numberWithBool: YES]
                                               forKey: NSURLIsExcludedFromBackupKey error:nil];//路径防icloud拷贝
    return fileName;
}

@end
