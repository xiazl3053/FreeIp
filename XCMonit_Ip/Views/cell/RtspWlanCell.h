//
//  RtspWlanCell.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/4/9.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RtspInfo.h"

@protocol RTSPLanDelegate <NSObject>

-(void)addDeviceInfo:(RtspInfo*)rtsp;

@end


@interface RtspWlanCell : UITableViewCell

@property (nonatomic,assign) id<RTSPLanDelegate> delegate;
@property (nonatomic,strong) RtspInfo *rtsp;

-(void)setDevInfo:(RtspInfo*)rtsp;

@end
