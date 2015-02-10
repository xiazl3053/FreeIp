//
//  AddDevViewController.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-20.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "AddDevViewController.h"
#import "CustomNaviBarView.h"
#import "IQKeyboardManager.h"
#import "XCDecoder.h"
#import "DeviceInfoDb.h"
#import "UtilsMacro.h"
#import "DevModel.h"
#import "XCNotification.h"
#import "AddDeviceService.h"
#import "Toast+UIView.h"
#import "ProgressHUD.h"
#import "ZBarSDK.h"
#import "MBProgressHUD.h"

@interface AddDevViewController ()<UITextFieldDelegate,ZBarReaderDelegate,MBProgressHUDDelegate>
{
    int num;
    BOOL upOrdown;
    BOOL bScane;
}
@property (nonatomic,assign) BOOL bTrue;
@property (nonatomic, retain) UIImageView * line;
@property (nonatomic,strong) UITextField *txtNo;
@property (nonatomic,strong) MBProgressHUD *mbHUD;
@property (nonatomic,strong) AddDeviceService *addDevice;

@end

@implementation AddDevViewController

-(void) dealloc
{
    [_txtNo removeFromSuperview];
    _txtNo = nil;
    [_mbHUD removeFromSuperview];
    _mbHUD = nil;
    _addDevice = nil;
    DLog(@"add dev dealloc");
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        bScane = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    _txtNo = [[UITextField alloc] initWithFrame:Rect(0, 100, kScreenWidth, 40)];
    [_txtNo setPlaceholder:XCLocalized(@"inputNO")];
    [_txtNo setKeyboardType:UIKeyboardTypeNumberPad];//UIKeyboardTypeNumberPad
    _txtNo.delegate = self;
    
    [_txtNo setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:_txtNo];
    [_txtNo setBorderStyle:UITextBorderStyleNone];
    UIImageView *imgPwd = [[UIImageView alloc] init];
    imgPwd.frame = Rect(0, 0, 20, 39.5);
    _txtNo.leftView = imgPwd;
    _txtNo.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtNo.leftViewMode = UITextFieldViewModeAlways;
    
    [super viewDidLoad];
    [self setNaviBarTitle:XCLocalized(@"AddCamera")];
    [self setNaviBarRightBtn:nil];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                    imgHighlight:@"NaviBtn_Back_H" target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    [_txtNo becomeFirstResponder];
    
    _mbHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_mbHUD];
    [self.view bringSubviewToFront:_mbHUD];
    _mbHUD.delegate = self;
    _mbHUD.labelText = XCLocalized(@"AddCamera");
    _bTrue = YES;
    [self.view setBackgroundColor:RGB(247, 247, 247)];
}

-(void)authNO:(NSString *)strInfo
{
    _txtNo.text = strInfo;
    [self authDevice];
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)doneKeyBoard
{
    if ([_txtNo isFirstResponder])
    {
        if (_txtNo.text.length>8)
        {
            [self authDevice];
        }else
        {
            [self.view makeToast:XCLocalized(@"serialLength") duration:1.0 position:@"center"];
        }
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)navBack
{
    if (!_bTrue)
    {
        return;
    }
    _txtNo.delegate = nil;
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)authDevice
{
    if (_txtNo.text.length < 9)
    {
        DLog(@"序列号错误");
        return;
    }
    [_txtNo resignFirstResponder];
    _bTrue = NO;
    __weak AddDevViewController *weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself.mbHUD show:YES];
    });
    if(_addDevice == nil)
    {
        _addDevice = [[AddDeviceService alloc] init];
    }
    __weak AddDevViewController *weakSelf = self;
    _addDevice.addDeviceBlock = ^(int nStatus)
    {
        NSString *strMsg = nil;
        switch (nStatus)
        {
            case 1:
                strMsg = XCLocalized(@"addOk");
                break;
            case 45:
                strMsg = XCLocalized(@"bindingError");
                break;
            case 44:
                strMsg = XCLocalized(@"serialError");
                break ;
            case 64:
                strMsg = XCLocalized(@"serialError");
                break;
            case -999:
                strMsg = XCLocalized(@"addTimeout");
                break;
            default:
                strMsg = XCLocalized(@"ServerException");
                break;
        }
        weakSelf.bTrue = YES;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [weakself.mbHUD hide:YES];
        });
        [weakSelf.view makeToast:strMsg];
        if (nStatus ==1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_DEVICE_LIST_VC object:nil];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
            {
               [weakSelf navBack];
            });
        }
    };
    [_addDevice queryDeviceIsExits:_txtNo.text auth:@""];
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


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField.text length] >= 13 )//当字符串长度到13个的时候，只有删除按钮可以使用
    {
        NSString *emailRegex = @"[0-9]";//正则表达式0-9
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        BOOL bFlag = [emailTest evaluateWithObject:string];//检测字符内容
        if(bFlag)
        {
            return NO;
        }
        else
        {
            return YES;
        }
        emailTest = nil;
        emailRegex = nil;
    }
    return YES;
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
