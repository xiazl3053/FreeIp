//
//  UploadImageService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/22.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FileDetail;
typedef void(^HttpUploadImage)(int nStatus);

@interface UploadImageService : NSObject

@property (nonatomic,copy) HttpUploadImage httpBlock;

-(void)requestUpload:(UIImage*)image;

@end



@interface FileDetail : NSObject
@property(strong,nonatomic) NSString *name;
@property(strong,nonatomic) NSData *data;
+(FileDetail *)fileWithName:(NSString *)name data:(NSData *)data;

@end
