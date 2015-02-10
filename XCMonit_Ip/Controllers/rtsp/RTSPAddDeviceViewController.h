//
//  RTSPAddDeviceViewController.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomViewController.h"
@class RtspInfo;

@interface RTSPAddDeviceViewController : CustomViewController

-(id)initWithRtsp:(RtspInfo*)rtspInfo;

-(void)setRtspInfo:(RtspInfo*)rtspInfo;

@end
