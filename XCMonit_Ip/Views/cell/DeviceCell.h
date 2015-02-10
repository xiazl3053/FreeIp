//
//  DeviceCell.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-22.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DeviceDelegate <NSObject>

@optional

-(void)playVideo:(NSString*)strNO name:(NSString*)strDevName type:(NSInteger)nType;

-(void)recordVideo:(NSString*)strNO name:(NSString*)strDevName line:(int)nLine;

@end


@interface DeviceCell : UITableViewCell

@property (nonatomic,strong) NSString *strDevNO;
@property (nonatomic,assign) id<DeviceDelegate> delegate;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) UILabel *lblStatus;
@property (nonatomic,strong) UILabel *lblDevNO;
@property (nonatomic,strong) NSString *strName;
@property (nonatomic,assign) NSInteger nType;
@property (nonatomic,assign) int nStatus;
-(void)removeTap;

-(void)setPlayModel;

@end
