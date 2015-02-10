//
//  UpdEmailViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/10.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "UpdEmailViewController.h"
#import "CustomNaviBarView.h"
#import "Toast+UIView.h"
#import "ProgressHUD.h"
#import "UpdEmailService.h"
#import "XCNotification.h"

@interface UpdEmailViewController ()

@property (nonatomic,strong) UITextField *txtEmail;
@property (nonatomic,strong) UpdEmailService *emailServer;

@end

@implementation UpdEmailViewController

-(void)initHeadView
{
  
    [self setNaviBarTitle:XCLocalized(@"updateEmail")];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    UIButton *right = [CustomNaviBarView createNormalNaviBarBtnByTitle:XCLocalized(@"save") target:self action:@selector(updateEmail)];
    [self setNaviBarRightBtn:right];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initHeadView];
    _txtEmail = [[UITextField alloc] initWithFrame:Rect(0, [CustomNaviBarView barSize].height+20, kScreenWidth, 39.5)];
    [self.view addSubview:_txtEmail];
    [_txtEmail setBorderStyle:UITextBorderStyleNone];
    [self.view setBackgroundColor:RGB(247, 247, 247)];
    UIImageView *imgPwd = [[UIImageView alloc] init];
    imgPwd.frame = Rect(0, 0, 20, 39.5);
    _txtEmail.leftView = imgPwd;
    _txtEmail.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtEmail.leftViewMode = UITextFieldViewModeAlways;
    UIColor *color = [UIColor grayColor];
    _txtEmail.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"email") attributes:@{NSForegroundColorAttributeName: color}];
    [_txtEmail setReturnKeyType:UIReturnKeyDone];
    [_txtEmail setBackgroundColor:[UIColor whiteColor]];
    _emailServer = [[UpdEmailService alloc] init];
}

-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)updateEmail
{
    [_txtEmail resignFirstResponder];
    NSString *strEmail = [_txtEmail text];
    if ([strEmail isEqualToString:@""]) {
        [self.view makeToast:XCLocalized(@"emailEmpty")];
        return;
    }
    
    if (![self validateEmail:strEmail])
    {
        [self.view makeToast:XCLocalized(@"emailError")];
        return;
    }
    
    if ([strEmail length]>kUSER_INFO_MAX_LENGTH)
    {
        [self.view makeToast:XCLocalized(@"emailThan64")];
        return ;
    }
    
    if (_emailServer)
    {
        __weak UpdEmailViewController *__weakSelf = self;
        _emailServer.httpBlock = ^(int nStatus)
        {
            dispatch_async(dispatch_get_main_queue(), ^{[ProgressHUD dismiss];});
            switch (nStatus) {
                case 1:
                {
                    [__weakSelf.view makeToast:XCLocalized(@"updateOK")];
                    [[NSNotificationCenter defaultCenter] postNotificationName:NS_UPDATE_USER_INFO_VC object:nil];
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.6 * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                    {
                        [__weakSelf navBack];
                    });
                }
                break;
                case 141:
                {
                    [__weakSelf.view makeToast:XCLocalized(@"emailBind")];
                }
                    break;
                default:
                {
                    [__weakSelf.view makeToast:XCLocalized(@"deleteDeviceFail_server")];
                }
                break;
            }
        };
        [_emailServer requestUpdEmail:strEmail];
        [ProgressHUD show:XCLocalized(@"updemailing")];
    }
    
}

- (BOOL) validateEmail: (NSString *) candidate
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:candidate];
}

-(void)dealloc
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


@end
