//
//  FirstStepViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/11/13.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "FirstStepViewController.h"
#import "CustomNaviBarView.h"
#import "RegisterAuthCode.h"
#import "ProgressHUD.h"
#import "Toast+UIView.h"
#import "DecodeJson.h"
#import "XCNotification.h"
#import "TwoStepViewController.h"
#import "UpdateForEmailService.h"
#import "XCNotification.h"

@interface FirstStepViewController ()

@property (nonatomic,strong) UITextField *txtUserName;
@property (nonatomic,strong) RegisterAuthCode *regService;
@property (nonatomic,assign) BOOL bAuth;
@property (nonatomic,assign) BOOL bError;
@property (nonatomic,strong) UpdateForEmailService *updAuthCode;

@end

@implementation FirstStepViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeKeyBoard) name:NSKEY_BOARD_RETURN_VC object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navBack) name:NS_UPDATE_PASSWROD_VC object:nil];

}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)closeKeyBoard
{
    [_txtUserName resignFirstResponder];
}

-(void)initHeadView
{
    
    [self setNaviBarTitle:XCLocalized(@"find_pwd")];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateHighlighted];
    [btn addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarLeftBtn:btn];
    UIButton *right = [CustomNaviBarView createNormalNaviBarBtnByTitle:XCLocalized(@"next_find") target:self action:@selector(nextStep)];
    [self setNaviBarRightBtn:right];
    
}

-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)nextStep
{
    if([_txtUserName isFirstResponder])
    {
        [_txtUserName resignFirstResponder];
    }
    NSString *strEmail = [[_txtUserName text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];//去除空格
    if ([strEmail isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"emailEmpty")];
        return ;
    }

    __block FirstStepViewController *__weakSelf =self;
    __block NSString *__strEmail = _txtUserName.text;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__weakSelf requestAuthCode:__strEmail];
    });
}

-(void)enterTwoView
{
    TwoStepViewController *twoView = [[TwoStepViewController alloc] init];
 //   [self addChildViewController:twoView];
    [self presentViewController:twoView animated:YES completion:nil];
}

-(void)requestAuthCode:(NSString *)strEmail
{
    __weak FirstStepViewController *__weakSelf = self;
    _updAuthCode.httpAuthCode=^(int nStatus)
    {
        [ProgressHUD dismiss];
        switch (nStatus) {
            case 1:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [__weakSelf.view makeToast:XCLocalized(@"VertifySucc")];
                    [__weakSelf performSelector:@selector(enterTwoView) withObject:nil afterDelay:2.0f];
                });
            }
            break ;
            case 171:
            {
                dispatch_async(dispatch_get_main_queue(),
               ^{
                   [__weakSelf.view makeToast:XCLocalized(@"VertifyExits")];
               });
            }
            break;
            case 172:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [__weakSelf.view makeToast:XCLocalized(@"VertifyEmail")];
                });
            }
            break;
            default:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [__weakSelf.view makeToast:XCLocalized(@"ServerException")];
                });
            }
            break;
        }
    };
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [ProgressHUD show:XCLocalized(@"VerifyAccount")];
    });
    [_updAuthCode requestAuthCode:strEmail];
    
}

-(void)authUsername:(NSString *)strUser
{
    if(_regService)
    {
        __weak FirstStepViewController *weakSelf =self;
        _regService.httpAuthBlock = ^(int nStatus)
        {
            
            dispatch_async(dispatch_get_main_queue(), ^{[ProgressHUD dismiss];});
            if(nStatus!=1)
            {
                weakSelf.bError= NO;
                TwoStepViewController *twoStep = [[TwoStepViewController alloc] init];
                [weakSelf presentViewController:twoStep animated:YES completion:nil];
            }
            else
            {
                [weakSelf.view makeToast:XCLocalized(@"UserInfoNotExits")];
                weakSelf.bError= YES;
            }
        };
        [_regService requestAuthUsername:strUser];
        dispatch_async(dispatch_get_main_queue(), ^{[ProgressHUD show:@"正在验证邮箱..."];});
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initHeadView];
    _txtUserName = [[UITextField alloc] initWithFrame:Rect(0, [CustomNaviBarView barSize].height+20, kScreenWidth, 39.5)];
    [self.view addSubview:_txtUserName];
    [_txtUserName setBorderStyle:UITextBorderStyleNone];
    [self.view setBackgroundColor:RGB(247, 247, 247)];
    UIImageView *imgPwd = [[UIImageView alloc] init];
    imgPwd.frame = Rect(0, 0, 20, 39.5);
    _txtUserName.leftView = imgPwd;
    _txtUserName.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtUserName.leftViewMode = UITextFieldViewModeAlways;
    UIColor *color = [UIColor grayColor];
    _txtUserName.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"Loginuser")
                                                                         attributes:@{NSForegroundColorAttributeName: color}];
    [_txtUserName setReturnKeyType:UIReturnKeyDone];
    [_txtUserName setBackgroundColor:[UIColor whiteColor]];
    [_txtUserName setKeyboardType:UIKeyboardTypeASCIICapable];
    _txtUserName.autocorrectionType = UITextAutocorrectionTypeNo;
    _txtUserName.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    
    _regService = [[RegisterAuthCode alloc] init];//判断用户名是否存在
    
    [_txtUserName setBackground:[UIImage imageNamed:@"text_back"]];
    _updAuthCode = [UpdateForEmailService sharedUpdateForEmailService];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
-(void)dealloc
{
    _txtUserName = nil;
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
