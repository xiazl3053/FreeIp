//
//  RTSPPlayViewController.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RtspInfo;
@interface RTSPPlayViewController : UIViewController


-(id)initWithContentRtsp:(RtspInfo*)rtspInfo channel:(NSInteger)nChannel;

@end
