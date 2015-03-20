//
//  VideoTopHud.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/13.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "VideoTopHud.h"

@implementation VideoTopHud

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.alpha = 1;
    
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height-0.2, self.frame.size.width, 0.1)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height-0.1, self.frame.size.width, 0.1)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:sLine1];
    [self addSubview:sLine2];
    
    UIImageView *downViewBg = [[UIImageView alloc] initWithFrame:Rect(0, 0, kScreenSourchHeight, frame.size.height)];
    [downViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    downViewBg.tag = 10001;
    [self addSubview:downViewBg];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(50,15,kScreenWidth-60,20)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [_lblName setTextColor:[UIColor blackColor]];
    [self addSubview:_lblName];
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    _doneButton.frame = CGRectMake(5,2.5,44,44);
    _doneButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _doneButton.showsTouchWhenHighlighted = YES;
//    [_doneButton addTarget:self action:@selector(doneDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_doneButton];
    _btnBD = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnBD setImage:[UIImage imageNamed:@"full_bd"] forState:UIControlStateNormal];
    [_btnBD setImage:[UIImage imageNamed:@""] forState:UIControlStateHighlighted];
    _btnBD.tag = 10002;
    _btnHD = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnHD setImage:[UIImage imageNamed:@"full_hd"] forState:UIControlStateNormal];
    [_btnHD setImage:[UIImage imageNamed:@""] forState:UIControlStateHighlighted];
    _btnHD.tag = 10003;
    _btnPtzView = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnPtzView setImage:[UIImage imageNamed:@"ptz_control"] forState:UIControlStateNormal];
       return  self;
}

-(void)doneDidTouch:(UIButton*)btnSender
{
    //send Message    Or  Delegate
}

-(void)addPtz
{
    [self addSubview:_btnPtzView];
}
-(void)addSwtich
{
    [self addSubview:_btnHD];
    [self addSubview:_btnBD];
}

@end
