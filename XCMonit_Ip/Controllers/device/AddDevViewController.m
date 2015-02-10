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

@interface AddDevViewController ()<UITextFieldDelegate>
{
    UIActivityIndicatorView *_viewActivity;
}
@property (nonatomic,strong) UITextField *txtNo;
@property (nonatomic,strong) UITextField *txtAuth;
@end

@implementation AddDevViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    _txtNo = [[UITextField alloc] initWithFrame:Rect(20, 100, 280, 40)];
    [_txtNo setBorderStyle:UITextBorderStyleBezel];
    [_txtNo setPlaceholder:NSLocalizedString(@"inputNO", nil)];
    [_txtNo setKeyboardType:UIKeyboardTypeNumberPad];//UIKeyboardTypeNumberPad
    _txtNo.delegate = self;
    [self.view addSubview:_txtNo];
    
//    _txtAuth = [[UITextField alloc] initWithFrame:Rect(20, 160, 280, 40)];
//    [_txtAuth setBorderStyle:UITextBorderStyleBezel];
//    [_txtAuth setPlaceholder:@"请输出验证码"];
//    [_txtAuth setKeyboardType:UIKeyboardTypeASCIICapable];
//    _txtAuth.delegate = self;
//    [self.view addSubview:_txtAuth];
    
    [super viewDidLoad];
    [self setNaviBarTitle:NSLocalizedString(@"AddCamera", nil)];
    [self setNaviBarRightBtn:nil];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                    imgHighlight:@"NaviBtn_Back_H" target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    [_txtNo becomeFirstResponder];
    
//    _viewActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
//    _viewActivity.center = self.view.center;
//    _viewActivity.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
//    _viewActivity.backgroundColor = [UIColor blackColor];
//    [self.view addSubview:_viewActivity];
}

-(void)doneKeyBoard
{
    if ([_txtNo isFirstResponder])
    {
        if (_txtNo.text.length>8) {
            [self authDevice];
        }else
        {
            [self.view makeToast:NSLocalizedString(@"serialLength", nil) duration:1.0 position:@"center"];
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
    _txtNo.delegate = nil;
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) dealloc
{
    _txtNo = nil;
}

-(void)authDevice
{
    if (_txtNo.text.length < 9)
    {
        DLog(@"序列号错误");
        return;
    }


    [ProgressHUD show:NSLocalizedString(@"Addcamera", nil)];
    AddDeviceService *addDevice = [[AddDeviceService alloc] init];
    __weak AddDevViewController *weakSelf = self;
    addDevice.addDeviceBlock = ^(int nStatus)
    {
        [ProgressHUD dismiss];
        NSString *strMsg = nil;
        switch (nStatus)
        {
            case 1:
                strMsg = NSLocalizedString(@"addOk",nil);
                break;
            case 45:
                strMsg = NSLocalizedString(@"bindingError", nil);
                break;
            case 44:
                strMsg = NSLocalizedString(@"serialError", nil);
                break ;
            case -999:
                strMsg= NSLocalizedString(@"addTimeout", nil);
                break;
            default:
                strMsg = NSLocalizedString(@"ServerException", nil);
                break;
        }
        [self.view makeToast:strMsg duration:2.0 position:@"center" title:NSLocalizedString(@"Addcamera", nil)];
        if (nStatus ==1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_DEVICE_LIST_VC object:nil];
            [weakSelf navBack];
        }
    };
    [addDevice requestAddDevice:_txtNo.text auth:@""];


}


#pragma mark 键盘事件 
//-(void)textFieldDidEndEditing:(UITextField *)textField
//{
//    //执行添加设备的操作
//    NSString *strNO = [_txtNo text];
//    if (strNO.length==0) {
//        //alertView;
//    }
//    NSError *error = nil;
//    XCDecoder *decode = [[XCDecoder alloc] initWithP2P:strNO error:&error];
//    if (error)
//    {
//        NSString *strTitle = nil;
//        switch (error.code) {
//            case CONNECT_P2P_SERVER:
//                strTitle = [error localizedDescription];
//                break;
//            case CONNECT_DEV_ERROR:
//                strTitle = [error localizedDescription];
//                break;
//            default:
//                break;
//        }
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"添加错误" message:strTitle delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//        [alert show];
//        decode = nil;
//        return;
//    }
//    decode = nil;
//    DevModel *devModel = [[DevModel alloc] initWithDev:@"设备" devNO:self.txtNo.text];
//    [DeviceInfoDb insertDevInfo:devModel];
//    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"添加设备" message:@"成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//    [alert show];
//    [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_DEVICE_LIST_VC object:nil];
//    [self navBack];
//}
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
