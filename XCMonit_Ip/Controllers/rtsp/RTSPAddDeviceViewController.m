//
//  RTSPAddDeviceViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RTSPAddDeviceViewController.h"
#import "CustomNaviBarView.h"
#import "IQKeyboardManager.h"
#import "XCNotification.h"
#import "Toast+UIView.h"
#import "RtspInfoDb.h"
#import "RtspInfo.h"
@interface RTSPAddDeviceViewController ()
{
    NSArray *segmentedArray;
    NSArray *segmentedArray1;
}

@property (nonatomic,strong) UITextField *txtName;
@property (nonatomic,strong) UITextField *txtAddress;
@property (nonatomic,strong) UITextField *txtPort;
@property (nonatomic,strong) UITextField *txtUser;
@property (nonatomic,strong) UITextField *txtPwd;
@property (nonatomic,strong) UISegmentedControl *segType;
@property (nonatomic,strong) UISegmentedControl *segChannel;

@end

@implementation RTSPAddDeviceViewController

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
    [self initUI];
    [self initViewInfo];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [IQKeyboardManager sharedManager].shouldShowTextFieldPlaceholder = YES;
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [IQKeyboardManager sharedManager].shouldShowTextFieldPlaceholder = NO;
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
-(void)doneKeyBoard
{
    if([_txtPwd isFirstResponder])
    {
        [_txtPwd resignFirstResponder];
    }
    else if([_txtAddress isFirstResponder])
    {
        [_txtAddress resignFirstResponder];
    }
    else if([_txtName isFirstResponder])
    {
        [_txtName resignFirstResponder];
    }
    else if([_txtPort isFirstResponder])
    {
        [_txtPort resignFirstResponder];
    }
    else if([_txtUser isFirstResponder])
    {
        [_txtUser resignFirstResponder];
    }
}

-(void)initViewInfo
{
    _txtName = [[UITextField alloc] initWithFrame:Rect(20, [CustomNaviBarView barSize].height+5, 280, 35)];
    _txtAddress = [[UITextField alloc] initWithFrame:Rect(20, _txtName.frame.origin.y+45, 280, 35)];
    _txtPort = [[UITextField alloc] initWithFrame:Rect(20, _txtAddress.frame.origin.y+45, 280, 35)];
    _txtUser = [[UITextField alloc] initWithFrame:Rect(20, _txtPort.frame.origin.y+45, 280, 35)];
    _txtPwd = [[UITextField alloc] initWithFrame:Rect(20, _txtUser.frame.origin.y+45, 280, 35)];
    [_txtName setPlaceholder:@"设备名"];
    [_txtAddress setPlaceholder:@"地  址"];
    [_txtPort setPlaceholder:@"端  口"];
    [_txtUser setPlaceholder:@"用户名"];
    [_txtPwd setPlaceholder:@"密  码"];
    
    [_txtName setBorderStyle:UITextBorderStyleBezel];
    [_txtAddress setBorderStyle:UITextBorderStyleBezel];
    [_txtPort setBorderStyle:UITextBorderStyleBezel];
    [_txtUser setBorderStyle:UITextBorderStyleBezel];
    [_txtPwd setBorderStyle:UITextBorderStyleBezel];
    
    [_txtName setText:@"Device1"];
    
    [_txtPwd setSecureTextEntry:YES];
    
    [_txtPort setKeyboardType:UIKeyboardTypeNumberPad];
    
    
    [self.view addSubview:_txtName];
    [self.view addSubview:_txtAddress];
    [self.view addSubview:_txtPort];
    [self.view addSubview:_txtUser];
    [self.view addSubview:_txtPwd];
    
    segmentedArray = [[NSArray alloc]initWithObjects:@"IPC",@"DVR",@"NVR",nil];
    //初始化UISegmentedControl
    _segType = [[UISegmentedControl alloc]initWithItems:segmentedArray];
    _segType.frame = CGRectMake(20.0, 300.0, 280.0, 30.0);
    _segType.selectedSegmentIndex = 1;//设置默认选择项索引
 //   segmentedControl.tintColor = [UIColor redColor];
    _segType.segmentedControlStyle = UISegmentedControlStyleBezeled;
    [self.view addSubview:_segType];
    
    segmentedArray1 = [[NSArray alloc]initWithObjects:@"1",@"4",@"8",@"16",@"32",nil];
    //初始化UISegmentedControl
    _segChannel = [[UISegmentedControl alloc]initWithItems:segmentedArray1];
    _segChannel.frame = CGRectMake(20.0, 340.0, 280.0, 30.0);
    _segChannel.selectedSegmentIndex = 2;//设置默认选择项索引
  //  segmentedControl1.tintColor = [UIColor redColor];
    _segChannel.segmentedControlStyle = UISegmentedControlStyleBezeled;
    [self.view addSubview:_segChannel];
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)initUI
{
    [self setNaviBarTitle:@"添加RTSP设备"];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    UIButton *right = [CustomNaviBarView createNormalNaviBarBtnByTitle:NSLocalizedString(@"save", "save") target:self action:@selector(updateDevName)];
    [self setNaviBarRightBtn:right];
}

-(void)updateDevName
{
    NSString *strName = _txtName.text;
    if ([strName isEqualToString:@""])
    {
        [self.view makeToast:@"设备名不能为空"];
        return ;
    }
    
    NSString *strAddress = _txtAddress.text;
    if ([strAddress isEqualToString:@""])
    {
        [self.view makeToast:@"地址不能为空"];
        return ;
    }
    
    NSString *strPort = _txtPort.text;
    if ([strPort isEqualToString:@""])
    {
        [self.view makeToast:@"端口不能为空"];
        return ;
    }
    
    NSString *strUser = _txtUser.text;
    NSString *strPwd = _txtPwd.text;
    NSString *strType = [segmentedArray objectAtIndex:_segType.selectedSegmentIndex];
    NSString *strChannel = [segmentedArray1  objectAtIndex:_segChannel.selectedSegmentIndex];
    RtspInfo *rtsp = [[RtspInfo alloc] init];
    rtsp.strAddress = strAddress;
    rtsp.strDevName = strName;
    rtsp.strUser = strUser;
    rtsp.strPwd = strPwd;
    rtsp.nPort = [strPwd integerValue];
    rtsp.strType = strType;
    rtsp.nChannel = [strChannel integerValue];
    [RtspInfoDb queryAllRtsp];
    BOOL bReturn = [RtspInfoDb addRtsp:rtsp];
    if (bReturn)
    {
        [self.view makeToast:@"添加成功"];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    else
    {
        DLog(@"添加失败");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

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
-(BOOL)shouldAutorotate
{
    return NO;
}
@end
