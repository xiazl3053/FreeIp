//
//  VideoTopHud.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/13.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoTopHud : UIView

@property (nonatomic,copy) NSString *strDevName;
@property (nonatomic,strong) UIButton *doneButton;
@property (nonatomic,strong) UILabel *lblName;
@property (nonatomic,strong) UIButton *btnHD;
@property (nonatomic,strong) UIButton *btnBD;
@property (nonatomic,strong) UIButton *btnPtzView;


-(void)addSwtich;
-(void)addPtz;

@end

