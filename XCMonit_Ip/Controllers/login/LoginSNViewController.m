//
//  LoginSNViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/7/17.
//  Copyright © 2015年 夏钟林. All rights reserved.
//

#import "LoginSNViewController.h"
#import "LoginSNService.h"
#import "XCNotification.h"
#import "ProgressHUD.h"
#import "Toast+UIView.h"
#import "UIView+Extension.h"
#import "GetSnService.h"
#import "PlayP2PViewController.h"
#import "PlayFourViewController.h"

#import "DeviceInfoModel.h"

@interface LoginSNViewController()<UITextFieldDelegate>
{
    LoginSNService *snService;
    UITextField *txtSN;
    UITextField *txtUser;
    UITextField *txtPwd;
    GetSnService *getSn;
    
}
@property (nonatomic,copy) NSString *strNo;
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
    [btnBack addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
    UILabel *lblName = [[UILabel alloc] initWithFrame:Rect(80, 25, kScreenWidth-160, 30)];
    [lblName setTextColor:RGB(255, 255, 255)];
    [headView addSubview:lblName];
    [lblName setText:XCLocalized(@"SNLogin")];
    [lblName setTextAlignment:NSTextAlignmentCenter];
    
}

-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)initWithMiddle
{
    
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(30, 100, kScreenWidth-60, 0.5)];
    [self.view addSubview:lblContent];
    [lblContent setBackgroundColor:UIColorFromRGBHex(0xd8e6ea)];
    
    UILabel *lblTemp = [[UILabel alloc] initWithFrame:Rect(kScreenWidth/2-40, 90, 80, 20)];
    [lblTemp setText:XCLocalized(@"Loginbtn")];
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
    txtSN.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"inputNO") attributes:@{NSForegroundColorAttributeName: color}];
    UIImageView *imgPwd = [[UIImageView alloc] init];
    imgPwd.frame = Rect(0, 0, 44, 44);
    imgPwd.image = [UIImage imageNamed:@"sn_login"];
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
    imgPwd1.frame = Rect(0, 0, 44, 44);
    imgPwd1.image = [UIImage imageNamed:@"sn_user"];
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
    imgPwd2.frame = Rect(0, 0, 44, 44);
    imgPwd2.image = [UIImage imageNamed:@"sn_pwd"];
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
    [txtPwd setSecureTextEntry:YES];
    
    txtPwd.delegate = self;
    txtSN.delegate = self;
    txtUser.delegate = self;
    
//
    UIButton *btnLogin = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLogin setBackgroundColor:RGB(15, 173, 225)];
    [btnLogin setTitle:XCLocalized(@"Loiginbtn") forState:UIControlStateNormal];
    [btnLogin setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    btnLogin.layer.masksToBounds = YES;
    btnLogin.layer.cornerRadius = 3;
    [self.view addSubview:btnLogin];
    [btnLogin addTarget:self action:@selector(loginServerInfo) forControlEvents:UIControlEventTouchUpInside];
    btnLogin.frame = Rect(30, txtPwd.y+txtPwd.height+20, kScreenWidth-60, 44);
    
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

-(void)loginServerInfo
{
    [ProgressHUD show:XCLocalized(@"logining")];
    [self performSelector:@selector(loginServer) withObject:nil afterDelay:0.5f];
}

-(void)loginServer
{
    if (snService == nil)
    {
        snService = [[LoginSNService alloc] init];
    }
    NSString *strUser = txtUser.text;
    NSString *strPwd = txtPwd.text;
    NSString *strNO = txtSN.text;
    if (strUser != nil && [strUser isEqualToString:@""]) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [ProgressHUD dismiss];
                       });
        [self.view makeToast:XCLocalized(@"userAuth")];
        return ;
    }
    if (strPwd != nil  && [strPwd isEqualToString:@""]) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [ProgressHUD dismiss];
                       });
        [self.view makeToast:XCLocalized(@"pwdAuth")];
        
        return;
    }
    if (strNO !=nil && [strNO isEqualToString:@""]) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [ProgressHUD dismiss];
                       });
        [self.view makeToast:XCLocalized(@"xuleihao")];
        return; 
    }
    __weak LoginSNViewController *__self = self;
    snService.sn_login = ^(int nStatus)
    {
        NSString *strInfo = nil;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [ProgressHUD dismiss];
        });
        switch (nStatus) {
            case 0:
            {
                strInfo = XCLocalized(@"ServerException");
            }
            break;
            case 1:
            {
               strInfo = @"OK";
            }
            break;
            case 191:
            {
                strInfo = XCLocalized(@"ServerException");
            }
            break;
            case 194:
            {
                strInfo = XCLocalized(@"3Error");
            }
            break;
            case 192:
            {
                strInfo = XCLocalized(@"serialError");
            }
            break;
            case 193:
            {
                strInfo = XCLocalized(@"authError");
            }
            break;
            default:
            {
                strInfo = XCLocalized(@"ServerException");
            }
            break;
        }
        if (nStatus == 1)
        {
            [__self enterSuccess];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [__self.view makeToast:strInfo];
            });
        }
    };
    _strNo = strNO;
    [snService requestLoginSN:strUser pwd:strPwd sn:strNO];
    
}

-(void)enterSuccess
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [ProgressHUD show:@"获取设备信息"];
    });
    [self performSelector:@selector(getServiceInfo) withObject:nil afterDelay:0.5f];
//    [self getServiceInfo];
    
}

-(void)getServiceInfo
{
    if (getSn==nil) {
        getSn = [[GetSnService alloc] init];
    }
    __weak LoginSNViewController *__self = self;
    getSn.getSnInfo = ^(int nStatus,int nAllCout)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ProgressHUD dismiss];
        });
        NSString *strInfo = @"";
        switch (nStatus)
        {
            case 1:
            {
                
            }
            break;
            case 0:
            {
                strInfo = XCLocalized(@"ServerException");
            }
            break;
            case 201:
            {
                
                strInfo = XCLocalized(@"ServerException");
            }
                break;
            case 202:
            {
                
                strInfo = XCLocalized(@"loginTime");
            }
            break;
            default:
            {
                
                strInfo = XCLocalized(@"ServerException");
            }
            break;
        }
        if (nStatus==1)
        {
            if (nAllCout == 1)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    PlayP2PViewController *playP2p = [[PlayP2PViewController alloc] initWithNO:__self.strNo name:__self.strNo format:0];
                    [__self presentViewController:playP2p animated:YES completion:nil];
                });
            }
            else if(nAllCout > 1)
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    DeviceInfoModel *devInfo = [[DeviceInfoModel alloc] init];
                    devInfo.strDevNO = __self.strNo;
                    devInfo.strDevType = [NSString stringWithFormat:@"DVR-%d",nAllCout];
                    devInfo.strDevName = __self.strNo;
                    PlayFourViewController *playFour = [[PlayFourViewController alloc] initWithSNDevice:devInfo];
                    [__self presentViewController:playFour animated:YES completion:nil];
                });
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [__self.view makeToast:strInfo];
            });
        }
    };
    [getSn requestSn:@"2134567890"];
}

-(void)dealloc
{
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return  YES;
}

-(void)closekeyBoard
{
    if ([txtUser isFirstResponder])
    {
        [txtUser resignFirstResponder];
    }
    else if([txtPwd isFirstResponder])
    {
        [txtPwd resignFirstResponder];
    }
    else
    {
        [txtSN resignFirstResponder];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closekeyBoard) name:NSKEY_BOARD_RETURN_VC object:nil];
}
#pragma mark 重力处理
- (BOOL)shouldAutorotate NS_AVAILABLE_IOS(6_0)
{
    return NO;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
