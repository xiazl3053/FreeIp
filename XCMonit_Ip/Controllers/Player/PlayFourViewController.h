//
//  PlayFourViewController.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/17.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CustomViewController.h"
@class DeviceInfoModel;
@interface PlayFourViewController : UIViewController

-(id)initWithDevInfo:(DeviceInfoModel*)devModel;
-(void)startPlayWithNO:(NSString*)strNO channel:(NSString*)strKey;
-(void)initToolBar;
@end
