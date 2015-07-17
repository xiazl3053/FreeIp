//
//  LoginSNViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/7/17.
//  Copyright © 2015年 夏钟林. All rights reserved.
//

#import "LoginSNViewController.h"
#import "LoginSNService.h"
#import "UIView+Extension.h"
@interface LoginSNViewController()
{
    LoginSNService *snService;
    UITextField *txtSN;
    UITextField *txtUser;
    UITextField *txtPwd;
    
}

@end

@implementation LoginSNViewController

-(void)initHeadView
{
    [self.view setBackgroundColor:UIColorFromRGBHex(0xf7f7f7)];
    
    UIView *headView = [[UIView alloc] initWithFrame:Rect(0, 0, kScreenWidth, 64)];
    [headView setBackgroundColor:RGB(15, 173, 225)];
    [self.view addSubview:headView];
    
    UIButton *btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [headView addSubview:btnBack];
    btnBack.frame = Rect(0, 20, 44, 44);
    [btnBack setImage:[UIImage imageNamed:@"NaviBtn_Back_h"] forState:UIControlStateNormal];
    [btnBack setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateHighlighted];
    
    UILabel *lblName = [[UILabel alloc] initWithFrame:Rect(80, 25, kScreenWidth-160, 30)];
    [lblName setTextColor:RGB(255, 255, 255)];
    [headView addSubview:lblName];
    [lblName setText:@"序列号登录"];
    [lblName setTextAlignment:NSTextAlignmentCenter];
    
}

-(void)initWithMiddle
{
    
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(30, 100, kScreenWidth-60, 0.5)];
    [self.view addSubview:lblContent];
    [lblContent setBackgroundColor:UIColorFromRGBHex(0xd8e6ea)];
    
    
    UILabel *lblTemp = [[UILabel alloc] initWithFrame:Rect(kScreenWidth/2-40, 90, 80, 20)];
    [lblTemp setText:@"登  录"];
    [lblTemp setBackgroundColor:UIColorFromRGBHex(0xf7f7f7)];
    [lblTemp setTextColor:UIColorFromRGBHex(0xbcc7cb)];
    [lblTemp setFont:XCFontInfo(12)];
    [lblTemp setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:lblTemp];
    UIColor *color = [UIColor grayColor];
    
    txtSN = [[UITextField alloc] initWithFrame:Rect(30, lblTemp.y+lblTemp.height+20,kScreenWidth-60, 44)];
    [txtSN setBorderStyle:UITextBorderStyleNone];
    [txtSN setBackgroundColor:RGB(255, 255, 255)];
    txtSN.layer.borderColor = UIColorFromRGBHex(0xc6cfd2).CGColor;
    txtSN.layer.borderWidth = 0.5;
    txtSN.layer.masksToBounds = YES;
    txtSN.layer.cornerRadius = 3;
    txtSN.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"Loginuser") attributes:@{NSForegroundColorAttributeName: color}];
    UIImageView *imgPwd = [[UIImageView alloc] init];
    imgPwd.frame = Rect(0, 15, 45, 17);
    imgPwd.image = [UIImage imageNamed:@"password_Icon"];
    imgPwd.contentMode = UIViewContentModeScaleAspectFit;
    txtSN.leftView = imgPwd;
    txtSN.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    txtSN.leftViewMode = UITextFieldViewModeAlways;
    [txtSN setFont:XCFontInfo(12)];
    [self.view addSubview:txtSN];
    
    
    txtUser = [[UITextField alloc] initWithFrame:Rect(30, txtSN.y+txtSN.height+10,kScreenWidth-60, 44)];
    [txtUser setBorderStyle:UITextBorderStyleNone];
    [txtUser setBackgroundColor:RGB(255, 255, 255)];
    txtUser.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"Loginuser") attributes:@{NSForegroundColorAttributeName: color}];
    UIImageView *imgPwd1 = [[UIImageView alloc] init];
    imgPwd1.frame = Rect(0, 15, 45, 17);
    imgPwd1.image = [UIImage imageNamed:@"userName_Icon"];
    imgPwd1.contentMode = UIViewContentModeScaleAspectFit;
    txtUser.leftView = imgPwd1;
    txtUser.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    txtUser.leftViewMode = UITextFieldViewModeAlways;
    txtUser.layer.borderColor = UIColorFromRGBHex(0xc6cfd2).CGColor;
    txtUser.layer.borderWidth = 0.5;
    txtUser.layer.masksToBounds = YES;
    txtUser.layer.cornerRadius = 3;
    [txtUser setFont:XCFontInfo(12)];
    [self.view addSubview:txtUser];
    
    txtPwd = [[UITextField alloc] initWithFrame:Rect(30, txtUser.y+txtUser.height+10,kScreenWidth-60, 44)];
    [txtPwd setBorderStyle:UITextBorderStyleNone];
    [txtPwd setBackgroundColor:RGB(255, 255, 255)];
    [txtPwd setFont:XCFontInfo(12)];
    UIImageView *imgPwd2 = [[UIImageView alloc] init];
    imgPwd2.frame = Rect(0, 15, 45, 17);
    imgPwd2.image = [UIImage imageNamed:@"password_Icon"];
    imgPwd2.contentMode = UIViewContentModeScaleAspectFit;
    txtPwd.leftView = imgPwd2;
    txtPwd.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    txtPwd.leftViewMode = UITextFieldViewModeAlways;
    txtPwd.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"Loginpwd") attributes:@{NSForegroundColorAttributeName: color}];
    txtPwd.layer.borderColor = UIColorFromRGBHex(0xc6cfd2).CGColor;
    txtPwd.layer.borderWidth = 0.5;
    txtPwd.layer.masksToBounds = YES;
    txtPwd.layer.cornerRadius = 3;
    [self.view addSubview:txtPwd];
    
    UIButton *btnLogin = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLogin setBackgroundColor:RGB(15, 173, 225)];
    [btnLogin setTitle:@"登录" forState:UIControlStateNormal];
    [btnLogin setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    btnLogin.layer.masksToBounds = YES;
    btnLogin.layer.cornerRadius = 3;
    [self.view addSubview:btnLogin];
    [btnLogin addTarget:self action:@selector(loginServer) forControlEvents:UIControlEventTouchUpInside];
    btnLogin.frame = Rect(30, txtPwd.y+txtPwd.height+20, kScreenWidth-60, 44);
    
}

-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initHeadView];
    [self initWithMiddle];
    
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
        NSString *strInfo = nil;
        switch (nStatus) {
            case 0:
            {
                
            }
            break;
            case 1:
            {
                
            }
            break;
            case 191:
            {
                
            }
            break;
            case 192:
            {
                
            }
                break;
            case 193:
            {
                
            }
            break;
            case 194:
            {
                
            }
            break;
            default:
                break;
        }
    };
    [snService requestLoginSN:@"admin" pwd:@"admin" sn:@"9743200000001"];
}

-(void)dealloc
{
    
}

@end
