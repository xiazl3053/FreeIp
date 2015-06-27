//
//  RegisterViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/3.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RegisterViewController.h"
#import "CustomNaviBarView.h"
#import "RegisterAuthCode.h"
#import "XCNotification.h"
#import "Toast+UIView.h"
#import "ProgressHUD.h"
#import "DecodeJson.h"

#define kFONT_SIZE_HEIGHT  13.0f

@interface RegisterViewController ()<UITextFieldDelegate>



@property (nonatomic,copy) NSString *strAuthCode16;
@property(nonatomic,strong) UITextField *txtName;
@property(nonatomic,strong) UITextField *txtPwd;
@property(nonatomic,strong) UITextField *txtPwdAuth;
@property(nonatomic,strong) UITextField *txtAuthCode;
@property(nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) UIButton *btnNext;
@property (nonatomic,strong) UIButton *btnRegister;
@property (nonatomic,assign) BOOL bEmailError;
@property (nonatomic,assign) BOOL bError;
@property (nonatomic,assign) BOOL bPwd;
@property (nonatomic,assign) BOOL bPwdLength;
@property (nonatomic,strong) RegisterAuthCode *regAuth;

@end

@implementation RegisterViewController

-(void)dealloc
{
    _txtName = nil;
    _txtPwd = nil;
    _txtPwdAuth = nil;
    _txtAuthCode = nil;
    _imgView = nil;
    _btnNext = nil;
    _btnRegister = nil;
    _regAuth = nil;
    _strAuthCode16 = nil;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initUI];
    [self initUIBody];
    _regAuth = [[RegisterAuthCode alloc] init];
    [self switchImg];
    _bError = YES;
    _bPwd = YES;
    [self.view setUserInteractionEnabled:YES];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hiddenKeyBoard)]];
}
-(void)getAuthCode
{
    if (_regAuth)
    {
        [_regAuth requestAuthCode];
        __weak RegisterViewController *__weakSelf = self;
        _regAuth.httpBlock = ^(NSString *strImg,int nStatus)
        {
            switch (nStatus) {
                case 1:
                {
                    __weakSelf.strAuthCode16 = strImg;
                    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@class/yzm2/phone_yzm.php?captchacheck=%@",
                                    kHTTP_Host,strImg];
                    NSData *data=[NSData dataWithContentsOfURL:[NSURL URLWithString:strUrl]];
                    UIImage *image=[UIImage imageWithData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __weakSelf.imgView.image = image;
                    });
                }
                break;
                default:
                {
                    __weakSelf.strAuthCode16 = @"";
                }
                break;
            }
        };
    }
}


-(void)initUI
{
    [self setNaviBarTitle:XCLocalized(@"RegisterView")];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateHighlighted];
    [btn addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarLeftBtn:btn];
    [self setNaviBarRightBtn:nil];
    [self.view setBackgroundColor:RGB(245, 245, 246)];
}

-(void)initUIBody
{
    _txtName = [[UITextField alloc] initWithFrame:Rect(45, [CustomNaviBarView barSize].height+44, kScreenWidth-90, 44)];
    [self.view addSubview:_txtName];
    UIImageView *nameImg = [[UIImageView alloc] initWithFrame:Rect(0, 15, 45, 17)];
    nameImg.image = [UIImage imageNamed:@"userName_Icon"];
    nameImg.contentMode = UIViewContentModeScaleAspectFit;
    
    
    UIImageView *pwdImg = [[UIImageView alloc] initWithFrame:Rect(0, 15, 45, 17)];
    pwdImg.image = [UIImage imageNamed:@"password_Icon"];
    pwdImg.contentMode = UIViewContentModeScaleAspectFit;
    
    UIImageView *pwdAuthImg = [[UIImageView alloc] initWithFrame:Rect(0, 15, 45, 17)];
    pwdAuthImg.image = [UIImage imageNamed:@"password_Icon"];
    pwdAuthImg.contentMode = UIViewContentModeScaleAspectFit;
    
    UIImageView *authImg = [[UIImageView alloc] initWithFrame:Rect(0, 15, 45, 17)];
    authImg.image = [UIImage imageNamed:@"auth_Icon"];
    authImg.contentMode = UIViewContentModeScaleAspectFit;
    
    _txtName.leftView = nameImg;//左边图片
    _txtName.leftViewMode = UITextFieldViewModeAlways;
    _txtName.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [_txtName setBorderStyle:UITextBorderStyleNone];
    _txtName.autocorrectionType = UITextAutocorrectionTypeNo;
    _txtName.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _txtName.returnKeyType = UIReturnKeyDone;
    _txtName.clearButtonMode = UITextFieldViewModeWhileEditing;
    [_txtName setBackgroundColor:RGB(255, 255, 255)];
    [_txtName setFont:[UIFont fontWithName:@"Helvetica" size:kFONT_SIZE_HEIGHT]];
    [_txtName setTextColor:RGB(15, 173, 225)];
    _txtName.tag = 10000;
    _txtName.delegate = self;
    
    _txtPwd = [[UITextField alloc] initWithFrame:Rect(45, _txtName.frame.origin.y+_txtName.frame.size.height+10, kScreenWidth-90, 44)];
    [self.view addSubview:_txtPwd];
    
    _txtPwd.leftView = pwdImg;
    _txtPwd.leftViewMode = UITextFieldViewModeAlways;
    _txtPwd.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    [_txtPwd setBorderStyle:UITextBorderStyleNone];
    _txtPwd.autocorrectionType = UITextAutocorrectionTypeNo;
    _txtPwd.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _txtPwd.returnKeyType = UIReturnKeyDone;
    _txtPwd.clearButtonMode = UITextFieldViewModeWhileEditing;
    _txtPwd.clearButtonMode = UITextFieldViewModeWhileEditing;
    [_txtPwd setSecureTextEntry:YES];
    [_txtPwd setFont:[UIFont fontWithName:@"Helvetica" size:kFONT_SIZE_HEIGHT]];
    [_txtPwd setBackgroundColor:RGB(255, 255, 255)];
    [_txtPwd setTextColor:RGB(15, 173, 225)];
    [_txtPwd setPlaceholder:XCLocalized(@"Loginpwd")];
    _txtPwd.tag = 10013;
    _txtPwd.delegate = self;
    
    _txtPwdAuth = [[UITextField alloc] initWithFrame:Rect(45, _txtPwd.frame.origin.y+_txtPwd.frame.size.height+10, kScreenWidth-90, 44)];
    [self.view addSubview:_txtPwdAuth];
    _txtPwdAuth.leftView = pwdAuthImg;
    _txtPwdAuth.leftViewMode = UITextFieldViewModeAlways;
    _txtPwdAuth.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [_txtPwdAuth setBorderStyle:UITextBorderStyleNone];
    _txtPwdAuth.autocorrectionType = UITextAutocorrectionTypeNo;
    _txtPwdAuth.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _txtPwdAuth.returnKeyType = UIReturnKeyDone;
    _txtPwdAuth.clearButtonMode = UITextFieldViewModeWhileEditing;
    [_txtPwdAuth setSecureTextEntry:YES];
    [_txtPwdAuth setTextColor:RGB(15, 173, 225)];
    [_txtPwdAuth setBackgroundColor:RGB(255, 255, 255)];
    [_txtPwdAuth setFont:[UIFont fontWithName:@"Helvetica" size:kFONT_SIZE_HEIGHT]];
    _txtPwdAuth.tag = 10001;
    _txtPwdAuth.delegate = self;
    
    _imgView = [[UIImageView alloc] initWithFrame:Rect(45, _txtPwdAuth.frame.origin.y+_txtPwdAuth.frame.size.height+10, 110, 40)];
    [self.view addSubview:_imgView];
    
    _imgView.image = [UIImage imageNamed:XCLocalized(@"auth_ico")];
    
    _btnNext = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnNext.frame = Rect(kScreenWidth-45-130,_txtPwdAuth.frame.origin.y+_txtPwdAuth.frame.size.height+23, 130, 20);
    [self.view addSubview:_btnNext];
    [_btnNext setTitle:XCLocalized(@"Next") forState:UIControlStateNormal];
    [_btnNext setTitleColor:RGB(15, 173, 225) forState:UIControlStateNormal];
    [_btnNext addTarget:self action:@selector(switchImg) forControlEvents:UIControlEventTouchUpInside];
    _btnNext.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:kFONT_SIZE_HEIGHT];
    
    _txtAuthCode = [[UITextField alloc] initWithFrame:Rect(45, _imgView.frame.origin.y+_imgView.frame.size.height+10, kScreenWidth-90, 40)];
    [self.view addSubview:_txtAuthCode];
    [_txtAuthCode setBorderStyle:UITextBorderStyleNone];
    _txtAuthCode.autocorrectionType = UITextAutocorrectionTypeNo;
    _txtAuthCode.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _txtAuthCode.returnKeyType = UIReturnKeyDone;
    _txtAuthCode.clearButtonMode = UITextFieldViewModeWhileEditing;
    [_txtAuthCode setTextColor:RGB(15, 173, 225)];
    _txtAuthCode.leftView = authImg;
    _txtAuthCode.leftViewMode = UITextFieldViewModeAlways;
    _txtAuthCode.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtAuthCode.backgroundColor = RGB(255, 255, 255);
    [_txtAuthCode setFont:[UIFont fontWithName:@"Helvetica" size:kFONT_SIZE_HEIGHT]];
    
    [_txtName setBackground:[UIImage imageNamed:@"text_back"]];
    [_txtPwd setBackground:[UIImage imageNamed:@"text_back"]];
    [_txtPwdAuth setBackground:[UIImage imageNamed:@"text_back"]];
    [_txtAuthCode setBackground:[UIImage imageNamed:@"text_back"]];
    
    
    _btnRegister = [UIButton  buttonWithType:UIButtonTypeCustom];
    [_btnRegister setTitle:XCLocalized(@"Loginregister") forState:UIControlStateNormal];
    [_btnRegister addTarget:self action:@selector(threadRegister) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnRegister];
    _btnRegister.frame = Rect(45, _txtAuthCode.frame.origin.y+_txtAuthCode.frame.size.height+25, kScreenWidth-90, 44);
    _btnRegister.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_btnRegister setBackgroundColor:RGB(15, 173, 225)];
    [_btnRegister setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnRegister.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    
    UIColor *color = [UIColor grayColor];
    _txtName.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"regUser") attributes:@{NSForegroundColorAttributeName: color}];
    _txtPwd.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"Loginpwd") attributes:@{NSForegroundColorAttributeName: color}];
    _txtPwdAuth.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"LoginpwdAgain") attributes:@{NSForegroundColorAttributeName: color}];
    _txtAuthCode.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"RegiAuth") attributes:@{NSForegroundColorAttributeName: color}];
}

-(void)hiddenKeyBoard
{
    if (_txtName.isFirstResponder)
    {
        [_txtName resignFirstResponder];
    }
    else if (_txtPwd.isFirstResponder)
    {
        [_txtPwd resignFirstResponder];
    }
    else if (_txtPwdAuth.isFirstResponder)
    {
        [_txtPwdAuth resignFirstResponder];
    }
    else if (_txtAuthCode.isFirstResponder)
    {
        [_txtAuthCode resignFirstResponder];
    }
}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hiddenKeyBoard) name:NSKEY_BOARD_RETURN_VC object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)switchImg
{
    __weak RegisterViewController *__weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [__weakSelf getAuthCode];
    });
}

-(void)threadRegister
{

    if ([_strAuthCode16 isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"ImageFail")];
        return;
    }

    NSString *strName = _txtName.text;
    if ([strName isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"userNull")];
        return;
    }
    
    if ([strName length]>64) {
        [self.view makeToast:XCLocalized(@"regNameLength")];
        return ;
    }
    
    NSString *strPwd = _txtPwd.text;
    if ([strPwd isEqualToString:@""]) {
        [self.view makeToast:XCLocalized(@"pwdNull")];
        return;
    }
    
    NSString *strAuthPwd = _txtPwdAuth.text;
    if ([strAuthPwd isEqualToString:@""]) {
        [self.view makeToast:XCLocalized(@"confirmPwd")];
        return ;
    }
    
    NSString *strAuthCode = _txtAuthCode.text;
    if ([strAuthCode isEqualToString:@""]) {
        [self.view makeToast:XCLocalized(@"picNull")];
        return ;
    }
    if (![DecodeJson validateEmail:_txtName.text])
    {
        [self.view makeToast:XCLocalized(@"emailError")];
        return;
    }
    else if([strPwd length] <6 || [strAuthPwd length] < 6)
    {
        [self.view makeToast:XCLocalized(@"pwdLength")];
        return;
    }
    else if(![strPwd isEqualToString:strAuthPwd])
    {
        [self.view makeToast:XCLocalized(@"TwoPwd")];
        return ;
    }
    __weak RegisterViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ProgressHUD show:XCLocalized(@"Registering")];
    });
    __block NSString *_strName = strName;
    __block NSString *_strPwd = strPwd;
    __block NSString *__strAuthCode = strAuthCode;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [weakSelf authRegister:_strName pwd:_strPwd code:__strAuthCode];
    });
}

-(void)authRegister:(NSString *)strUser pwd:(NSString*)strPwd code:(NSString *)strCode
{
    [_regAuth requestRegister:strUser pwd:strPwd auth:strCode code:_strAuthCode16];
    __weak RegisterViewController *weakSelf = self;
    _regAuth.httpReg = ^(int nStatus)
    {
        switch (nStatus) {
            case 1:
            {
                [ProgressHUD dismiss];
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [weakSelf.view makeToast:XCLocalized(@"RegSuc")];
                });
                [weakSelf performSelector:@selector(navBack) withObject:nil afterDelay:2.0f];
            }
            break;
            case 161:
            {
                //验证码错误
                [ProgressHUD dismiss];
                [weakSelf.view makeToast:XCLocalized(@"RegPic")];
            }
            break;
            case 162:
            {
                //数据错误
                [ProgressHUD dismiss];
                [weakSelf.view makeToast:XCLocalized(@"RegData")];
            }
            break;
            default:
            {
                //超时
                [ProgressHUD dismiss];
                [weakSelf.view makeToast:XCLocalized(@"RegTimeout")];
            }
            break;
        }
    };
}

-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 验证输入内容
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == 10000)
    {
        if ([_txtName.text isEqualToString:@""])
        {
            return ;
        }
        __weak RegisterViewController *weakSelf = self;
        if (![DecodeJson validateEmail:_txtName.text])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view makeToast:XCLocalized(@"emailError")];
                weakSelf.bError = NO;
            });
            return ;
        }
        //authUser
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            [weakSelf authUsername];
        });
    }
    else if(textField.tag == 10001)
    {
        if(![_txtPwd.text isEqualToString:_txtPwdAuth.text])
        {
            _bPwd = NO;
            __weak RegisterViewController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view makeToast:XCLocalized(@"TwoPwd")];
            });
            return;
        }
        _bPwd = YES;
    }
    else if(textField.tag == 10013)
    {
        if ([_txtPwd.text length]<6)
        {
            _bPwdLength = NO;
            __weak RegisterViewController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [weakSelf.view makeToast:XCLocalized(@"pwdLength")];
            });
        }
        else
        {
            _bPwdLength = YES;
        }
    }
}

-(void)authUsername
{
    __weak RegisterViewController *weakSelf =self;
    if([_txtName.text length] > kUSER_INFO_MAX_LENGTH)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view makeToast:XCLocalized(@"regThan64")];
        });
    }
    if(_regAuth)
    {
        _regAuth.httpAuthBlock = ^(int nStatus)
        {
            if(nStatus!=1)
            {
                [weakSelf.view makeToast:XCLocalized(@"UsernameAlready")];
                weakSelf.bError = NO;
            }else
            {
                weakSelf.bError = YES;
            }
        };
        [_regAuth requestAuthUsername:_txtName.text];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
