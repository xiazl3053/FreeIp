//
//  TwoStepViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/11/13.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "TwoStepViewController.h"
#import "CustomNaviBarView.h"
#import "ProgressHUD.h"
#import "Toast+UIView.h"
#import "UpdateForEmailService.h"
#import "UserInfo.h"
#import "XCNotification.h"
#import "LoginViewController.h"
#import "UserInfo.h"
@interface TwoStepViewController ()
{
    NSTimer *_timer;
    int nSecond;
}


@property (nonatomic,strong) UITextField *txtPwd;
@property (nonatomic,strong) UITextField *txtAuth;
@property (nonatomic,strong) UITextField *txtCode;
@property (nonatomic,strong) UIButton *btnResend;
@property (nonatomic,strong) UpdateForEmailService *emailService;
@property (nonatomic,strong) UILabel *lblInfo;
//@property (nonatomic,strong) NSTimer *timer;


@end

@implementation TwoStepViewController


-(void)initHeadView
{
    [self setNaviBarTitle:XCLocalized(@"find_pwd")];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateHighlighted];
    [btn addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarLeftBtn:btn];
    UIButton *right = [CustomNaviBarView createNormalNaviBarBtnByTitle:XCLocalized(@"Save") target:self action:@selector(nextStep)];
    [self setNaviBarRightBtn:right];
    
}

-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)nextStep
{
    /*

     */
    
    NSString *strNewPwd = _txtPwd.text;
    NSString *strConPwd = _txtAuth.text;
    if ([strNewPwd isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"pwdNull")];
        return;
    }
    if ([strNewPwd length]<6)
    {
        [self.view makeToast:XCLocalized(@"pwdLength")];
        return;
    }
    if ([strConPwd isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"confirmPwd")];
        return;
    }
    NSString *strCode = _txtCode.text;
    if ([strCode isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"vertiEmpty")];
        return;
    }
    
    __weak TwoStepViewController *twoView = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [twoView updatePassword];
    });
}

-(void)backLogin
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NS_UPDATE_PASSWROD_VC object:nil];
    }];

}

-(void)updatePassword
{
    __weak TwoStepViewController *twoView = self;
    _emailService.httpUpdPwd = ^(int nStatus)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ProgressHUD dismiss];
        });
        switch (nStatus) {
            case 1:
            {
                dispatch_async(dispatch_get_main_queue(),
               ^{
                   [twoView.view makeToast:XCLocalized(@"updateOK")];
                   [twoView performSelector:@selector(backLogin) withObject:nil afterDelay:2.0f];
               });
            }
            break;
            case 181:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                     [twoView.view makeToast:XCLocalized(@"vertifyTimeout")];
                });
            }
            break;
            case 182:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                      [twoView.view makeToast:XCLocalized(@"vertifyUser")];
                });
            }
            break;
            case 183:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                     [twoView.view makeToast:XCLocalized(@"vertifyEmpty")];
                });
            }
            break;
            case 184:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                       [twoView.view makeToast:XCLocalized(@"vertifyError")];
                });
            }
            break;
            default:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                     [twoView.view makeToast:XCLocalized(@"ServerException")];
                });
            }
            break;
        }
    };
    dispatch_async(dispatch_get_main_queue(),
    ^{
          [ProgressHUD show:XCLocalized(@"updpwding")];
          [twoView closeKeyboard];
    });
    [_emailService requestUpdForEmail:_txtPwd.text code:_txtCode.text];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initHeadView];
    
    _lblInfo = [[UILabel alloc] initWithFrame:Rect(45, [CustomNaviBarView barSize].height+20, kScreenWidth-90, 15)];
    [self.view addSubview:_lblInfo];
    [_lblInfo setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    NSString *strInfo = [NSString stringWithFormat:@"%@:",XCLocalized(@"alSend")];
    [_lblInfo setText:strInfo];
    [_lblInfo setTextColor:RGB(146, 146, 146)];
    
    UILabel *lblEmail = [[UILabel alloc] initWithFrame:Rect(45, [CustomNaviBarView barSize].height+35, kScreenWidth-90, 15)];
    [self.view addSubview:lblEmail];
    [lblEmail setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    NSString *strEmail = [NSString stringWithFormat:@"%@",[UserInfo sharedUserInfo].strEmail];
    [lblEmail setText:strEmail];
    [lblEmail setTextColor:RGB(146, 146, 146)];
    
    _txtPwd = [[UITextField alloc] initWithFrame:Rect(45, [CustomNaviBarView barSize].height+60, kScreenWidth-90, 39.5)];
    [self.view addSubview:_txtPwd];
    [_txtPwd setBorderStyle:UITextBorderStyleNone];
    [self.view setBackgroundColor:RGB(247, 247, 247)];
    UIImageView *imgPwd = [[UIImageView alloc] init];
    imgPwd.frame = Rect(0, 11, 45, 17);
    imgPwd.image = [UIImage imageNamed:@"userName_Icon"];
    imgPwd.contentMode = UIViewContentModeScaleAspectFit;
    _txtPwd.leftView = imgPwd;
    _txtPwd.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtPwd.leftViewMode = UITextFieldViewModeAlways;
    UIColor *color = [UIColor grayColor];
    _txtPwd.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"NewPwd") attributes:@{NSForegroundColorAttributeName: color}];
    [_txtPwd setReturnKeyType:UIReturnKeyDone];
    [_txtPwd setBackgroundColor:[UIColor whiteColor]];
    [_txtPwd setSecureTextEntry:YES];
    [_txtPwd setBorderStyle:UITextBorderStyleNone];
    _txtPwd.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    
    _txtAuth = [[UITextField alloc] initWithFrame:Rect(45, _txtPwd.frame.origin.y+_txtPwd.frame.size.height+10, kScreenWidth-90, 39.5)];
    [self.view addSubview:_txtAuth];
    [_txtAuth setBorderStyle:UITextBorderStyleNone];
    [self.view setBackgroundColor:RGB(247, 247, 247)];
    UIImageView *imgAuth = [[UIImageView alloc] init];
    imgAuth.frame = Rect(0, 11, 45, 17);
    imgAuth.image = [UIImage imageNamed:@"password_Icon"];
    imgAuth.contentMode = UIViewContentModeScaleAspectFit;
    _txtAuth.leftView = imgAuth;
    _txtAuth.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtAuth.leftViewMode = UITextFieldViewModeAlways;

    _txtAuth.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"confirmNewPwd") attributes:@{NSForegroundColorAttributeName: color}];
    [_txtAuth setReturnKeyType:UIReturnKeyDone];
    [_txtAuth setBackgroundColor:[UIColor whiteColor]];
    [_txtAuth setSecureTextEntry:YES];
    [_txtAuth setBorderStyle:UITextBorderStyleNone];
    _txtAuth.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    
    _txtCode = [[UITextField alloc] initWithFrame:Rect(45, _txtAuth.frame.origin.y+_txtAuth.frame.size.height+10, (kScreenWidth-90)/2, 39.5)];
    [self.view addSubview:_txtCode];
    [_txtCode setBorderStyle:UITextBorderStyleNone];
    [self.view setBackgroundColor:RGB(247, 247, 247)];
    UIImageView *imgCode = [[UIImageView alloc] init];
    imgCode.frame = Rect(0, 11, 45, 17);
    imgCode.contentMode = UIViewContentModeScaleAspectFit;
    _txtCode.leftView = imgCode;
    imgCode.image = [UIImage imageNamed:@"auth_Icon"];
    _txtCode.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtCode.leftViewMode = UITextFieldViewModeAlways;
    
    _txtCode.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"vertifyCode") attributes:@{NSForegroundColorAttributeName: color}];
    [_txtCode setReturnKeyType:UIReturnKeyDone];
    [_txtCode setBackgroundColor:[UIColor whiteColor]];
    [_txtCode setBorderStyle:UITextBorderStyleNone];
    _txtCode.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    
    [_txtCode setKeyboardType:UIKeyboardTypeASCIICapable];
    _txtCode.autocorrectionType = UITextAutocorrectionTypeNo;
    _txtCode.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    
    _btnResend = [UIButton buttonWithType:UIButtonTypeCustom];
    
    
    
    [_btnResend setBackgroundImage:[UIImage imageNamed:@"btnBG"] forState:UIControlStateNormal];
    [_btnResend setBackgroundImage:[UIImage imageNamed:@"btnCl"] forState:UIControlStateHighlighted];
    
    [_btnResend setTitle:XCLocalized(@"resend") forState:UIControlStateNormal];
    [_btnResend setTitleColor:RGB(67, 67, 67) forState:UIControlStateNormal];
    [_btnResend setFrame:Rect(_txtCode.frame.size.width+_txtCode.frame.origin.x, _txtCode.frame.origin.y,(kScreenWidth-90)/2,39)];
    _btnResend.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    
    [_btnResend addTarget:self action:@selector(ResendEmail) forControlEvents:UIControlEventTouchUpInside];
    
    [_txtPwd setBackground:[UIImage imageNamed:@"text_back"]];
    [_txtAuth setBackground:[UIImage imageNamed:@"text_back"]];
    [_txtCode setBackground:[UIImage imageNamed:@"text_back"]];
    
    [self.view addSubview:_txtPwd];
    [self.view addSubview:_txtAuth];
    [self.view addSubview:_txtCode];
    [self.view addSubview:_btnResend];
    
    [self.view setBackgroundColor:RGB(247, 247, 247)];
 
    _emailService = [UpdateForEmailService sharedUpdateForEmailService];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeKeyboard) name:NSKEY_BOARD_RETURN_VC object:nil];
    nSecond = 59;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(animation1) userInfo:nil repeats:YES];
    _btnResend.enabled = NO;
}

-(void)animation1
{
    if (nSecond==0)
    {
        _btnResend.enabled  = YES;
        [_btnResend setTitle:XCLocalized(@"resend") forState:UIControlStateNormal];
        [_timer invalidate];
        return ;
    }
    NSString *strInfo = [NSString stringWithFormat:@"%d %@",nSecond,XCLocalized(@"nSecondSend")];
    [_btnResend setTitle:strInfo forState:UIControlStateNormal];

    nSecond--;
}

#pragma mark 重力处理
- (BOOL)shouldAutorotate NS_AVAILABLE_IOS(6_0)
{
    return NO;
}
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
-(void)closeKeyboard
{
    if ([_txtPwd isFirstResponder])
    {
        [_txtPwd resignFirstResponder];
    }
    else if([_txtAuth isFirstResponder])
    {
        [_txtAuth resignFirstResponder];
    }
    else if([_txtCode isFirstResponder])
    {
        [_txtCode resignFirstResponder];
    }
}

-(void)ResendEmail
{
    _btnResend.enabled = NO;
    __weak TwoStepViewController *twoView = self;
    _emailService.httpAuthCode = ^(int nStatus)
    {
        [ProgressHUD dismiss];
        switch (nStatus) {
            case 1:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [twoView.view makeToast:XCLocalized(@"VertifySucc")];
                });
                
            }
            break;
            default:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [twoView.view makeToast:XCLocalized(@"ServerException")];
                });
            }
            break;
        }
    };
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [ProgressHUD show:XCLocalized(@"sendCode")];
    });
    [_emailService requestAuthCode:[UserInfo sharedUserInfo].strUser];
    nSecond = 59;
    _timer = nil;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(animation1) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
