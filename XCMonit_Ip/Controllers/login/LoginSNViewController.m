//
//  LoginSNViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/7/17.
//  Copyright © 2015年 夏钟林. All rights reserved.
//

#import "LoginSNViewController.h"
#import "LoginSNService.h"

@interface LoginSNViewController()
{
    LoginSNService *snService;
}

@end

@implementation LoginSNViewController

-(void)initHeadView
{
    UIView *headView = [[UIView alloc] initWithFrame:Rect(0, 0, kScreenWidth, 64)];
    [headView setBackgroundColor:RGB(15, 173, 225)];
    [self.view addSubview:headView];
    
    UIButton *btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [headView addSubview:btnBack];
    btnBack.frame = Rect(0, 20, 44, 44);
    [btnBack setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    [btnBack setImage:[UIImage imageNamed:@""] forState:UIControlStateHighlighted];
    
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

-(void)loginServer
{
    if (snService == nil)
    {
        snService = [[LoginSNService alloc] init];
    }
    snService.sn_login = ^(int nStatus)
    {
        
    };
    [snService requestLoginSN:@"" pwd:@"" sn:@""];
}

-(void)dealloc
{
    
}

@end
