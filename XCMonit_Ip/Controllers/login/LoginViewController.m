//
//  XCLoginViewController.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-19.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//
#import "LoginViewController.h"
#import "IndexViewController.h"
#import "UtilsMacro.h"
#import "LoginSNService.h"
#import "IQKeyboardManager.h"
#import "UserModel.h"
#import "DeviceInfoDb.h"
#import "Toast+UIView.h"
#import "LoginService.h"
#import "LoginInfo.h"
#import "XCNotification.h"
#import "ProgressHUD.h"
#import "RTSPListViewController.h"
#import "UIView+Extension.h"

#import "RegisterViewController.h"
#import "QCheckBox.h"
#import "FirstStepViewController.h"
#import "GuessLoginService.h"
#import "GuessListViewController.h"


//FFMPEG 在程序开始中调用

//#include "libswresample/swresample.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"

#define kLoginViewOriginY  kScreenHeight*0.5
#define kLoginViewDragHeight   150
#define kFONT_LOGIN_SIZE       14.0f

@interface LoginViewController ()<UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource>
{
    UITapGestureRecognizer *_tapGestureRecognizer;
    UIView  *headView;
    LoginSNService *loginSN;
}

@property (nonatomic,strong) UIButton *btnLogin;
@property (nonatomic,strong) UIButton *btnRegin;
@property (nonatomic,strong) UIImageView *imgBg;
@property (nonatomic,strong) UITextField *txtUser;
@property (nonatomic,strong) UITextField *txtPwd;
@property (nonatomic,strong) LoginService *xcService;
@property (nonatomic,strong) QCheckBox *check;
@property (nonatomic,assign) BOOL bLogin;
@property (nonatomic,strong) QCheckBox *autoLogin;
@property (nonatomic,strong) UIButton *btnFind;
@property (nonatomic,strong) UIImageView *imgGuess;


@property (nonatomic,strong) GuessLoginService *guessLogin;

@property (nonatomic,strong) UIPickerView *pickView;

@property (nonatomic,strong) NSMutableArray *arySql;

@end

@implementation LoginViewController
//void (* performMessage)(id,SEL);
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {

    }
    return self;
}
-(void)message
{
    DLog(@"message?");
}
-(void)initUI
{
    av_register_all();
    avcodec_register_all();
    
    CGFloat fTxtHeight = isPhone6p ? 46 : 39.5;

    headView = [[UIView alloc] initWithFrame:Rect(0, 0, self.view.width,64)];
    [self.view addSubview:headView];
    [headView setBackgroundColor:RGB(15,173,225)];
    UILabel *lblName = [[UILabel alloc] initWithFrame:Rect(0, 30, kScreenWidth, 25)];
    [headView addSubview:lblName];
    [lblName setTextColor:[UIColor whiteColor]];
    [lblName setText:XCLocalized(@"Loginbtn")];
    [lblName setTextAlignment:NSTextAlignmentCenter];
    [lblName setFont:XCFontInfo(24)];
    [self.view setBackgroundColor:RGB(245, 245, 246)];
    
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(30, 100, kScreenWidth-60, 0.5)];
    [self.view addSubview:lblContent];
    [lblContent setBackgroundColor:UIColorFromRGBHex(0xd8e6ea)];
    
    
    UILabel *lblTemp = [[UILabel alloc] initWithFrame:Rect(kScreenWidth/2-40, 90, 80, 20)];
    [lblTemp setText:@"账号密码登录"];
    [lblTemp setBackgroundColor:UIColorFromRGBHex(0xf7f7f7)];
    [lblTemp setTextColor:UIColorFromRGBHex(0xbcc7cb)];
    [lblTemp setFont:XCFontInfo(12)];
    [lblTemp setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:lblTemp];
    
    _txtUser = [[UITextField alloc] initWithFrame:CGRectMake(30, 120 , kScreenWidth-60, 44)];
    _txtPwd = [[UITextField alloc] initWithFrame:CGRectMake(30, _txtUser.frame.origin.y+_txtUser.frame.size.height+10, _txtUser.width, 44)];
    
    [_txtUser setBorderStyle:UITextBorderStyleNone];
    [_txtPwd setBorderStyle:UITextBorderStyleNone];
    _txtUser.autocorrectionType = UITextAutocorrectionTypeNo;
    _txtUser.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _txtUser.returnKeyType = UIReturnKeyDone;
    _txtUser.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    UIImageView *imgUser = [[UIImageView alloc] init];
    imgUser.frame = Rect(0, 15, 45, 17);
    imgUser.image = [UIImage imageNamed:@"userName_Icon"];
    imgUser.contentMode = UIViewContentModeScaleAspectFit;
    [_txtUser setReturnKeyType:UIReturnKeyNext];
    [_txtUser setKeyboardType:UIKeyboardTypeASCIICapable];
    _txtUser.leftView = imgUser;
    _txtUser.leftViewMode = UITextFieldViewModeAlways;
    _txtUser.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [_txtUser setTextColor:RGB(15, 173, 225)];
    [_txtUser setBackgroundColor:RGB(255, 255, 255)];
    [_txtPwd setReturnKeyType:UIReturnKeyDone];
    [_txtPwd setKeyboardType:UIKeyboardTypeASCIICapable];
    _txtPwd.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    UIImageView *imgPwd = [[UIImageView alloc] init];
    imgPwd.frame = Rect(0, 15, 45, 17);
    imgPwd.image = [UIImage imageNamed:@"password_Icon"];
    imgPwd.contentMode = UIViewContentModeScaleAspectFit;
    _txtPwd.leftView = imgPwd;
    _txtPwd.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtPwd.leftViewMode = UITextFieldViewModeAlways;
    [_txtPwd setBackgroundColor:RGB(255, 255, 255)];
    [_txtPwd setTextColor:RGB(15, 173, 225)];
    
    
    _txtUser.layer.borderColor = UIColorFromRGBHex(0xc6cfd2).CGColor;
    _txtUser.layer.borderWidth = 0.5;
    _txtUser.layer.masksToBounds = YES;
    _txtUser.layer.cornerRadius = 3;
    
    _txtPwd.layer.borderWidth = 0.5;
    _txtPwd.layer.masksToBounds = YES;
    _txtPwd.layer.cornerRadius = 3;
    _txtPwd.layer.borderColor = UIColorFromRGBHex(0xc6cfd2).CGColor;
    
    UIColor *color = [UIColor grayColor];
    _txtUser.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"Loginuser") attributes:@{NSForegroundColorAttributeName: color}];
    _txtPwd.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"Loginpwd") attributes:@{NSForegroundColorAttributeName: color}];
    
    _txtUser.delegate = self;
    _txtPwd.delegate = self;
    
    _txtUser.tag = 1;
    _txtPwd.tag = 2;
    
    [_txtPwd setSecureTextEntry:YES];
    [_txtUser setFont:[UIFont fontWithName:@"Helvetica" size:kFONT_LOGIN_SIZE]];
    [_txtPwd setFont:[UIFont fontWithName:@"Helvetica" size:kFONT_LOGIN_SIZE]];
    
    _check = [[QCheckBox alloc] initWithDelegate:self];
    
    UIFont *font = [UIFont fontWithName:@"Helvetica" size:kFONT_LOGIN_SIZE];
    
    CGSize labelsize = [XCLocalized(@"autoLogin") sizeWithFont:font constrainedToSize:CGSizeMake(200.0f, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
    
    _check.frame = Rect(30, _txtPwd.frame.origin.y+_txtPwd.frame.size.height+12, 100, 26);
    [_check setTitle:XCLocalized(@"saveLogin") forState:UIControlStateNormal];
    [_check setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    
    [_check.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:kFONT_LOGIN_SIZE]];
    [self.view addSubview:_check];
    
    _check.checked = [DeviceInfoDb querySavePwd];
    
    _autoLogin = [[QCheckBox alloc] initWithDelegate:self];
    
    _autoLogin.frame = Rect(kScreenWidth-65-labelsize.width, _txtPwd.frame.origin.y+_txtPwd.frame.size.height+12, labelsize.width+20, 26);
    [_autoLogin setTitle:XCLocalized(@"autoLogin") forState:UIControlStateNormal];
    [_autoLogin setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    
    [_autoLogin.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:kFONT_LOGIN_SIZE]];
    
    [self.view addSubview:_autoLogin];
    _autoLogin.checked = [DeviceInfoDb queryLogin];
    
    _btnLogin = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnRegin = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnFind = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnLogin setFrame:CGRectMake(30, _autoLogin.frame.origin.y+_autoLogin.frame.size.height+12, kScreenWidth-60, 39)];
    
    
    [_btnLogin setBackgroundImage:[UIImage imageNamed:@"btnBG"] forState:UIControlStateNormal];
    [_btnLogin setBackgroundImage:[UIImage imageNamed:@"btnCl"] forState:UIControlStateHighlighted];
    
    
    [_btnFind setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [_btnFind setTitleColor:RGB(15, 173, 225) forState:UIControlStateNormal];
    [_btnFind setTitle:XCLocalized(@"find_pwd") forState:UIControlStateNormal];
    
    _btnFind.titleLabel.font = XCFontInfo(15);
    CGSize findSize = [XCLocalized(@"find_pwd") sizeWithFont:XCFontInfo(15) constrainedToSize:CGSizeMake(200.0f, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
    [_btnFind setFrame:Rect(kScreenWidth/2-findSize.width/2,_btnLogin.frame.origin.y+_btnLogin.frame.size.height+20, findSize.width,25)];
    
    [_btnLogin setTitle:XCLocalized(@"Loginbtn") forState:UIControlStateNormal];
    [_btnLogin setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [_btnRegin setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    [_btnRegin setTitleColor:RGB(252, 173, 113) forState:UIControlStateHighlighted];
    [_btnRegin setTitle:XCLocalized(@"RegisterView") forState:UIControlStateNormal];
    [_btnRegin setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    _btnRegin.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:22.0f];
    
    [_btnRegin addTarget:self action:@selector(registerServver) forControlEvents:UIControlEventTouchUpInside];
    [_btnLogin addTarget:self action:@selector(loginServer) forControlEvents:UIControlEventTouchUpInside];
    [_btnFind addTarget:self action:@selector(findPwd) forControlEvents:UIControlEventTouchUpInside];
    
    _imgGuess = [[UIImageView alloc] initWithFrame:Rect(0, kScreenHeight-81.5+HEIGHT_MENU_VIEW(20, 0), 82.5, 81.5)];
    _imgGuess.image = [UIImage imageNamed:XCLocalized(@"guessImg")];
//    [self.view addSubview:_imgGuess];
    [_imgGuess addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginGuess)]];
    [_imgGuess setUserInteractionEnabled:YES];
    
//    [self.view addSubview:_imgBg];
    [self.view addSubview:_txtUser];
    [self.view addSubview:_txtPwd];
    [self.view addSubview:_btnLogin];
    [headView addSubview:_btnRegin];
    
    [_btnRegin setFrame:Rect(kScreenWidth - 100,30,90,25)];
    [self.view addSubview:_btnFind];
    _guessLogin = [[GuessLoginService alloc] init];
    
    UILabel *lblContent1 = [[UILabel alloc] initWithFrame:Rect(30, _btnFind.y+_btnFind.height+20, kScreenWidth-60, 0.5)];
    [self.view addSubview:lblContent1];
    [lblContent1 setBackgroundColor:UIColorFromRGBHex(0xd8e6ea)];
    
    
    UILabel *lblTemp1 = [[UILabel alloc] initWithFrame:Rect(kScreenWidth/2-40, _btnFind.y+_btnFind.height+10, 80, 20)];
    [lblTemp1 setText:@"其他方式登录"];
    [lblTemp1 setBackgroundColor:UIColorFromRGBHex(0xf7f7f7)];
    [lblTemp1 setTextColor:UIColorFromRGBHex(0xbcc7cb)];
    [lblTemp1 setFont:XCFontInfo(12)];
    [lblTemp1 setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:lblTemp1];
    
    UIButton *btnSN = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSN setTitle:@"序列号登录" forState:UIControlStateNormal];
    [btnSN setBackgroundColor:RGB(252, 173, 113)];
    [btnSN setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnSN.layer.masksToBounds = YES;
    btnSN.layer.cornerRadius = 3;
    
    UIButton *btnGuess = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnGuess setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnGuess setTitle:@"游客登录" forState:UIControlStateNormal];
    [btnGuess setBackgroundColor:RGB(0, 218, 95)];
    [self.view addSubview:btnSN];
    [self.view addSubview:btnGuess];
    btnSN.frame = Rect(30, lblTemp1.y+lblTemp1.height+20,kScreenWidth-60, 44);
    btnGuess.frame = Rect(30, btnSN.y+btnSN.height+11, kScreenWidth-60, 44);
    
    [btnSN addTarget:self action:@selector(loginSN) forControlEvents:UIControlEventTouchUpInside];
    [btnGuess addTarget:self action:@selector(loginGuess) forControlEvents:UIControlEventTouchUpInside];
}

-(void)loginSN
{
//    NSString *strUser = [_txtUser text];
//    NSString *strPwd = [_txtPwd text];
//    if (strUser == nil || [strUser isEqualToString:@""])
//    {
//        DLog(@"");
//        [self.view makeToast:XCLocalized(@"userAuth")];
//        return ;
//    }
//    if (strPwd == nil || [strPwd isEqualToString:@""])
//    {
//        DLog(@"");
//        [self.view makeToast:XCLocalized(@"pwdAuth")];
//        return ;
//    }
//    if(loginSN==nil)
//    {
//        loginSN = [[LoginSNService alloc] init];
//    }
//    [loginSN requestLoginSN:strUser pwd:strPwd sn:@"9743200000001"];
    
}

-(void)loginGuess
{
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [ProgressHUD show:XCLocalized(@"logining")];
    });
    
    __weak LoginViewController *__weakSelf = self;
    
    _guessLogin.httpGuessBlock = ^(int nStatus)
    {
        [ProgressHUD dismiss];
        if (nStatus==1)
        {
            DLog(@"登录成功");
            GuessListViewController *index = [[GuessListViewController alloc] init];
            [__weakSelf presentViewController:index animated:YES completion:^{}];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [__weakSelf.view makeToast:XCLocalized(@"ServerException")];
            });
        }
    };
    [_guessLogin connectionHttpLogin];
}

-(void)findPwd
{
    FirstStepViewController *first = [[FirstStepViewController alloc] init];
    [self presentViewController:first animated:YES completion:nil];
}

-(void)GotoRTSPView
{
    RTSPListViewController *rtsp = [[RTSPListViewController alloc] init];
    [self presentViewController:rtsp animated:YES completion:^{}];
}

-(void)registerServver
{
    RegisterViewController *regView = [[RegisterViewController alloc] init];
    [self presentViewController:regView animated:YES completion:^{}];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
    [self.view setBackgroundColor:UIColorFromRGB(242,242,246)];
    
    [self initUI];
    _bLogin = NO;
    self.view.userInteractionEnabled = YES;
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hiddenKey)]];
    NSArray *array = [DeviceInfoDb queryUserInfo];
    if (array.count>0)
    {
        UserModel *userModel = [array objectAtIndex:0];
        [self setLoginInfo:userModel.strUser pwd:userModel.strPwd];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePwdInfo) name:NS_UPDATE_PASSWROD_VC object:nil];
    
    array = nil;
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([DeviceInfoDb queryLogin])
    {
        [self loginServer];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doneKeyBoard) name:NSKEY_BOARD_RETURN_VC object:nil];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self];

}
-(void)hiddenKey
{
    if ([_txtUser isFirstResponder])
    {
        [_txtUser resignFirstResponder];
    }
    else if([_txtPwd isFirstResponder])
    {
        [_txtPwd resignFirstResponder];
    }
}
-(void)doneKeyBoard
{
    if([_txtPwd isFirstResponder])
    {
        [_txtPwd resignFirstResponder];
    }
    else
    {
        [_txtUser resignFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)loginServer
{
//    if (UIApplicationOpenSettingsURLString != NULL)
//    {
//        NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//        [[UIApplication sharedApplication] openURL:appSettings];
//    }
//    return ;
    NSString *nsUser = [_txtUser text];
    NSString *nsPwd = [_txtPwd text];
    if(_bLogin)
    {
        return ;
    }
    _bLogin = YES;
    if ([nsUser isEqualToString:@""] || [nsUser length]==0) {
        [self.view makeToast:XCLocalized(@"userAuth")];
        _bLogin = NO;
        return ;
    }else if([nsPwd isEqualToString:@""] || [nsPwd length]==0)
    {
        _bLogin = NO;
        [self.view makeToast:XCLocalized(@"pwdAuth")];
        return ;
    }
    
    BOOL bCheck = _check.checked;
    int nSave = bCheck ? 1 : 0;
    int nLogin = _autoLogin.checked ? 1 : 0;
    __block int __nSave = nSave;
    __block int __nLogin = nLogin;
#if 0
    _nLoginService = [[NewLoginService alloc] init];
    __weak LoginViewController *__weakSelf = self;
    
    _nLoginService.httpBlock = ^(LoginInfo *login,int nStatus)
    {
        DLog(@"nStatus:%d",nStatus);
    };
    [_nLoginService requestLogin:nsUser pwd:nsPwd];
#endif
#if 1
    _xcService = [[LoginService alloc] init];
    __weak LoginViewController *__weakSelf = self;
    //进入新的界面先
    dispatch_async(dispatch_get_main_queue(), ^{
        [ProgressHUD show:XCLocalized(@"logining") viewInfo:__weakSelf.view];
    });

    _xcService.httpBlock = ^(LoginInfo *login,int nStatus)
    {
        [ProgressHUD dismiss];
        switch (nStatus) {
            case 1:
            {
                [DeviceInfoDb updateSavePwd:__nSave];
                [DeviceInfoDb updateLogin:__nLogin];
                
                UserModel *userModel = [[UserModel alloc] initWithUser:__weakSelf.txtUser.text pwd:__weakSelf.txtPwd.text];
                [DeviceInfoDb insertUserInfo:userModel];
                IndexViewController *index = [IndexViewController sharedIndexViewController];
                [__weakSelf presentViewController:index animated:YES completion:^{}];
                [index setInit];
            }
            break;
            case 2:
                [__weakSelf.view makeToast:XCLocalized(@"ServerException")];
                break;
            case 0:
                [__weakSelf.view makeToast:XCLocalized(@"authError")];
                break;
            default:
            {
                [__weakSelf.view makeToast:XCLocalized(@"loginTime")];
            }
            break;
        }
        __weakSelf.bLogin = NO;
    };
    [_xcService connectionHttpLogin:nsUser pwd:nsPwd];
#endif
}

-(void)updatePwdInfo
{
    DLog(@"updatePwdInfo");
    NSArray *array = [DeviceInfoDb queryUserInfo];
    if (array.count>0)
    {
        UserModel *userModel = [array objectAtIndex:0];
        [self setLoginInfo:userModel.strUser pwd:userModel.strPwd];
    }
}

#pragma mark 重力处理
- (BOOL)shouldAutorotate
{
    return NO;
}
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
 //   [self loginViewKeyboardOpen];
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{

  //  [self loginViewKeyboardClose];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _txtUser)
    {
        [_txtUser resignFirstResponder];
        [_txtPwd becomeFirstResponder];
    }
    else if (textField == _txtPwd)
    {
        [self loginServer];
    }
    return YES;
}

-(void)setLoginInfo:(NSString*)strUser pwd:(NSString*)strPwd
{
    _txtUser.text = strUser;
    if([DeviceInfoDb querySavePwd])
    {
        _txtPwd.text = strPwd;
    }
}
-(void)dealloc
{
    _imgGuess = nil;
    _imgBg = nil;
    
    _xcService = nil;
    _txtUser = nil;
    _txtPwd = nil;
    _check = nil;
    _autoLogin = nil;
    _btnLogin = nil;
    _btnRegin = nil;
    _imgBg = nil;
    DLog(@"login view controller dealloc");
}

#pragma mark pickerView Delegate
// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 0;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 0;
}


@end



