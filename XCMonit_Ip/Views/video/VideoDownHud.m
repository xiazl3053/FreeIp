//
//  VideoDownHud.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/13.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "VideoDownHud.h"

@implementation VideoDownHud


-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.alpha = 1;
    [self setBackgroundColor:[UIColor clearColor]];
    
    UILabel *sLine3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.1, kScreenWidth, 0.2)];
    sLine3.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.3, kScreenWidth, 0.2)] ;
    sLine4.backgroundColor = [UIColor whiteColor];
    sLine3.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine4.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:sLine3];
    [self addSubview:sLine4];
    
    UIImageView *downViewBg = [[UIImageView alloc] initWithFrame:Rect(0, 0, kScreenSourchHeight, frame.size.height)];
    [downViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    [self addSubview:downViewBg];
    
    _playbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playbtn setImage:[UIImage imageNamed:@"full_play"] forState:UIControlStateNormal];
//    [_playbtn addTarget:self action:@selector(playWithAction:) forControlEvents:UIControlEventTouchUpInside];
    [_playbtn setImage:[UIImage imageNamed:@"full_stop"] forState:UIControlStateSelected];
    _playbtn.tag = 1001;
    [self addSubview:_playbtn];
    
     _captureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_captureBtn setImage:[UIImage imageNamed:@"full_snap"] forState:UIControlStateNormal];
    [_captureBtn setImage:[UIImage imageNamed:@"shotopic_h"] forState:UIControlStateHighlighted];
//    [_captureBtn addTarget:self action:@selector(shotoPic:) forControlEvents:UIControlEventTouchUpInside];
    _captureBtn.tag = 1003;
    
    _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_recordBtn setImage:[UIImage imageNamed:@"full_record"] forState:UIControlStateNormal];
//    [_recordBtn addTarget:self action:@selector(recordVideo) forControlEvents:UIControlEventTouchUpInside];
    [_recordBtn setImage:[UIImage imageNamed:@"record_sel"] forState:UIControlStateSelected];
    [_recordBtn setImage:[UIImage imageNamed:@"record_select"] forState:UIControlStateHighlighted];
    _recordBtn.tag = 1004;
    [self addSubview:_captureBtn];
    [self addSubview:_recordBtn];
    return self;
}
-(void)playWithAction:(UIButton*)sender
{
    
}
-(void)shotoPic:(UIButton *)sender
{
    
}
-(void)recordVideo
{
    
}
@end
