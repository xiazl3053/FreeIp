//
//  PlayCloudViewController.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/26.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DeviceInfoModel;
@interface PlayCloudViewController : UIViewController

-(id)initWithSNDevice:(DeviceInfoModel*)devInfo;
-(id)initWithDev:(DeviceInfoModel*)devInfo;

@end
