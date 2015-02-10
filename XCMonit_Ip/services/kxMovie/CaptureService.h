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

+(BOOL)captureToPhotoAlbum:(UIView *)_glView;

@end
