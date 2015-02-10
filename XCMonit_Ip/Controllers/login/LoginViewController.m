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
#import "IQKeyboardManager.h"
#import "UserModel.h"
#import "DeviceInfoDb.h"
#import "Toast+UIView.h"
#import "LoginService.h"
#import "LoginInfo.h"
#import "XCNotification.h"
#import "ProgressHUD.h"
#import "RTSPListViewController.h"
#define kLoginViewOriginY     kScreenHeight*0.5
#define kLoginViewDragHeight   150


@interface LoginViewController ()<UITextFieldDelegate>
{
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@property (nonatomic,strong) UIActivityIndicatorView  *viewActivity;
@property (nonatomic,strong) UIButton *btnLogin;
@property (nonatomic,strong) UIButton *btnRegin;
@property (nonatomic,strong) UIImageView *imgBg;
@property (nonatomic,strong) UITextField *txtUser;
@property (nonatomic,strong) UITextField *txtPwd;
@property (nonatomic,strong) LoginService *xcService;



@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {

    }
    return self;
}
-(void)initUI
{
    _imgBg = [[UIImageView alloc] initWithFrame:self.view.frame];
    _txtUser = [[UITextField alloc] initWithFrame:CGRectMake(20, 250, 280, 40)];
    _txtPwd = [[UITextField alloc] initWithFrame:CGRectMake(20, 300, 280, 40)];
    
    [_imgBg setImage:[UIImage imageNamed:@"loginBG"]];
    
    [_txtUser setBorderStyle:UITextBorderStyleBezel];
    [_txtPwd setBorderStyle:UITextBorderStyleBezel];
    _txtUser.autocorrectionType = UITextAutocorrectionTypeNo;
    _txtUser.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _txtUser.returnKeyType = UIReturnKeyDone;
    _txtUser.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    
    
    [_txtUser setReturnKeyType:UIReturnKeyNext];
    [_txtUser setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [_txtPwd setReturnKeyType:UIReturnKeyDone];
    [_txtPwd setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [_txtUser setPlaceholder:NSLocalizedString(@"Loginuser", nil)];
    [_txtPwd setPlaceholder:NSLocalizedString(@"Loginpwd", nil)];
 //   [_txtUser setPlaceholder:@"请输入用户名"];
 //   [_txtPwd setPlaceholder:@"请输入"];
    _txtUser.delegate = self;
    _txtPwd.delegate = self;
    
    _txtUser.tag = 1;
    _txtPwd.tag = 2;
    
    [_txtPwd setSecureTextEntry:YES];
    _btnLogin = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnRegin = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnLogin setFrame:CGRectMake(20, 360, 280, 39)];
    [_btnLogin setBackgroundImage:[UIImage imageNamed:@"btnBG"] forState:UIControlStateNormal];
    [_btnRegin setFrame:CGRectMake(80, 410, 160, 39)];
 //   [_btnRegin setBackgroundImage:[UIImage imageNamed:@"btnBG"] forState:UIControlStateNormal];
   
    [_btnLogin setTitle:NSLocalizedString(@"Loginbtn",nil) forState:UIControlStateNormal];
 //   [_btnLogin setTitle:@"登录" forState:UIControlStateNormal];
    _btnRegin.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_btnRegin setTitleColor:RGB(21, 100, 230) forState:UIControlStateNormal];
    [_btnRegin setTitle:NSLocalizedString(@"Loginregister", nil) forState:UIControlStateNormal];
//    [_btnRegin setTitle:@"注册" forState:UIControlStateNormal];
    [_btnRegin addTarget:self action:@selector(registerServver) forControlEvents:UIControlEventTouchUpInside];
    [_btnLogin addTarget:self action:@selector(loginServer) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *btnRTSP = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnRTSP addTarget:self action:@selector(GotoRTSPView) forControlEvents:UIControlEventTouchUpInside];
    [btnRTSP setTitleColor:RGB(21, 100, 230) forState:UIControlStateNormal];
    [btnRTSP setTitle:@"RTSP" forState:UIControlStateNormal];
    
    btnRTSP.frame = Rect(240, kScreenHeight-35, 60, 30);
    
    [self.view addSubview:_imgBg];
    [self.view addSubview:_txtUser];
    [self.view addSubview:_txtPwd];
    [self.view addSubview:_btnLogin];
    [self.view addSubview:_btnRegin];
    [self.view addSubview:btnRTSP];
}

-(void)GotoRTSPView
{
    RTSPListViewController *rtsp = [[RTSPListViewController alloc] init];
    [self presentViewController:rtsp animated:YES completion:^{}];
}

-(void)registerServver
{
    NSString *textURL = @"http://www.freeip.com/index.php?r=site/signup";
    NSURL *cleanURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", textURL]];
    [[UIApplication sharedApplication] openURL:cleanURL];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
    [self.view setBackgroundColor:UIColorFromRGB(242,242,246)];
    
    [self initUI];
    
    self.view.userInteractionEnabled = YES;
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    
    NSArray *array = [DeviceInfoDb queryUserInfo];
    if (array.count>0) {
        UserModel *userModel = [array objectAtIndex:0];
        [self setLoginInfo:userModel.strUser pwd:userModel.strPwd];
    }
    
    
    array = nil;
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
    [_tapGestureRecognizer removeTarget:self action:@selector(handleTap)];
    
}
-(void)handleTap
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
        [self loginServer];
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
    NSString *nsUser = [_txtUser text];
    NSString *nsPwd = [_txtPwd text];
    if ([nsUser isEqualToString:@""] || [nsUser length]==0) {
        [self.view makeToast:NSLocalizedString(@"userAuth", "userAuth")];
        return ;
    }else if([nsPwd isEqualToString:@""] || [nsPwd length]==0)
    {
        [self.view makeToast:NSLocalizedString(@"pwdAuth", "pwdAuth")];
        return ;
    }
    
    UserModel *userModel = [[UserModel alloc] initWithUser:nsUser pwd:nsPwd];
    [DeviceInfoDb insertUserInfo:userModel];
    //进入新的界面先
    [ProgressHUD show:NSLocalizedString(@"logining", "logining")];
    _xcService = [[LoginService alloc] init];
    __weak LoginViewController *__weakSelf = self;
    _xcService.httpBlock = ^(LoginInfo *login,int nStatus)
    {
        [ProgressHUD dismiss];
        switch (nStatus) {
            case 1:
            {
                IndexViewController *index = [IndexViewController sharedIndexViewController];
                [__weakSelf presentViewController:index animated:YES completion:^{}];
                [index setInit];
            }
            break;
            case 2:
                [__weakSelf.view makeToast:NSLocalizedString(@"ServerException", "ServerException")];
                break;
            case 0:
                [__weakSelf.view makeToast:NSLocalizedString(@"authError", "authError")];
                break;
            default:
            {
                [__weakSelf.view makeToast:NSLocalizedString(@"loginTime", "loginTime")];
            }
            break;
        }
    };
    [_xcService connectionHttpLogin:nsUser pwd:nsPwd];

}



#pragma mark 重力处理
- (BOOL)shouldAutorotate NS_AVAILABLE_IOS(6_0)
{
    return NO;
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
    _txtPwd.text = strPwd;
}
-(void)dealloc
{
    _xcService = nil;
    _btnLogin = nil;
    _btnRegin = nil;
    _imgBg = nil;
    DLog(@"login view controller dealloc");
}


@end
