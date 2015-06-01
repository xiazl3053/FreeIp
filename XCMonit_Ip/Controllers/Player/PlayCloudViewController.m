//
//  PlayCloudViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/26.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "UIView+Extension.h"
#import "CloudDecode.h"
#import "PlayCloudViewController.h"
#import "TimeView.h"

@interface PlayCloudViewController ()
{
    UIView *topView;
    UIView *downView;
    UILabel *_lblName;
    CloudDecode *clondDec;
}

@end

@implementation PlayCloudViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:RGB(255, 255, 255)];
    [self initBodyView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

-(void)initBodyView
{
    topView = [[UIView alloc] initWithFrame:Rect(0, 0, self.view.height,49)];
    [self.view addSubview:topView];
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, topView.frame.size.height-0.2, kScreenWidth, 0.1)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, topView.frame.size.height-0.1, kScreenWidth, 0.1)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [topView addSubview:sLine1];
    [topView addSubview:sLine2];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,15,kScreenWidth-60,20)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:@"回放"];
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    
    [_lblName setTextColor:[UIColor whiteColor]];
    [topView addSubview:_lblName];
    
    UIButton *_doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    _doneButton.frame = CGRectMake(5,2.5,44,44);
    _doneButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:_doneButton];
    
    UIImageView *topViewBg = [[UIImageView alloc] initWithFrame:topView.bounds];
    [topViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    topViewBg.tag = 10088;
    [topView insertSubview:topViewBg atIndex:0];
    
    downView = [[UIView alloc] initWithFrame:Rect(0, self.view.width-120, self.view.height,120)];
    [self.view addSubview:downView];
    
    UIImageView *downViewBg = [[UIImageView alloc] initWithFrame:downView.bounds];
    [downViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    downViewBg.tag = 10089;
    [downView insertSubview:downViewBg atIndex:0];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    clondDec = [[CloudDecode alloc] initWithCloud:@"9743200000001" channel:0 codeType:1];
}


-(void)doneDidTouch
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGFloat fWidth,fHeight;
    if(IOS_SYSTEM_8)
    {
        fWidth = self.view.width;
        fHeight = self.view.height;
    }
    else
    {
        fWidth = self.view.height;
        fHeight = self.view.width;
    }
    
    topView.frame = Rect(0, 0, fWidth, 49);
    _lblName.frame = Rect(30, 15, fWidth-60, 20);
    [topView viewWithTag:10088].frame = topView.bounds;
    
    downView.frame = Rect(0, fHeight-120, fWidth, 120);
    [downView viewWithTag:10089].frame = downView.bounds;
}

-(BOOL)prefersStatusBarHidden
{
    return  YES;
}

-(BOOL)shouldAutorotate
{
    return  NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return  UIInterfaceOrientationMaskLandscapeRight;
}




@end
