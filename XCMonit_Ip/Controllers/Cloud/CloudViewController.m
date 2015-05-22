//
//  CloudViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/19.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "CloudViewController.h"


@interface CloudViewController ()
{
    UIView *headView;
    UIView *downView;
    UILabel *_progressLabel;
    UILabel *_lblName;
    UIButton *_doneButton;
}
@end

@implementation CloudViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:RGB(255, 255, 255)];
    [self initHeadView];
    [self initBodyView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)initHeadView
{
    headView = [[UIView alloc] initWithFrame:Rect(0,0,kScreenSourchHeight,50)];
    [self.view addSubview:headView];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,15,kScreenWidth-60,20)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:XCLocalized(@"Playback")];
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [_lblName setTextColor:[UIColor blackColor]];
    [headView addSubview:_lblName];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    _doneButton.frame = CGRectMake(5,2.5,44,44);
    _doneButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [headView addSubview:_doneButton];
    
    _progressLabel = [[UILabel alloc] initWithFrame:Rect(0, 0, 60, 20)];
    [_progressLabel setTextAlignment:NSTextAlignmentCenter];
    [_progressLabel setTextColor:[UIColor redColor]];
    [_progressLabel setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [_progressLabel setAlpha:0.6f];
 
}

-(void)initBodyView
{
    downView = [[UIView alloc] initWithFrame:Rect(0,kScreenHeight,kScreenSourchHeight,110)];
    [self.view addSubview:downView];
}



-(void)doneDidTouch:(UIButton *)btnSender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(BOOL)shouldAutorotate{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

@end
