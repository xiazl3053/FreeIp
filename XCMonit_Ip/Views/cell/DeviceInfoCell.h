//
//  DeviceInfoCell.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/18.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceInfoCell : UITableViewCell

@property (nonatomic,strong) UILabel *lblDevInfo;
@property (nonatomic,strong) UILabel *lblContext;

-(void)setDevInfo:(NSString*)strInfo context:(NSString*)strContext;

@end
