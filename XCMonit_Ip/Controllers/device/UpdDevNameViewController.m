//
//  UpdDevNameViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/20.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "UpdDevNameViewController.h"
#import "CustomNaviBarView.h"
#import "UtilsMacro.h"
#import "Toast+UIView.h"
#import "XCNotification.h"
#import "UpdNameService.h"
#import "ProgressHUD.h"
@interface UpdDevNameViewController ()<UITextViewDelegate>
{
    UITextView *_txtView;
}
@property (nonatomic,strong) UpdNameService *updNameService;
@property (nonatomic,copy) NSString *strNo;
@property (nonatomic,copy) NSString *strName;
@end

@implementation UpdDevNameViewController

-(void)dealloc
{
    _updNameService = nil;
    _strNo = nil;
    _strName = nil;
    [_txtView removeFromSuperview];
    _txtView = nil;
    DLog(@"updDevice Name dealloc");
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
    [self setNaviBarTitle:XCLocalized(@"updDevName")];
    
    UIButton *left = [CustomNaviBarView createNormalNaviBarBtnByTitle:XCLocalized(@"cancel") target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:left];
    UIButton *right = [CustomNaviBarView createNormalNaviBarBtnByTitle:XCLocalized(@"save") target:self action:@selector(updateDevName)];
    [self setNaviBarRightBtn:right];
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(10, [CustomNaviBarView barSize].height+10, 300, 16)];
    [self.view addSubview:lblContent];
    [lblContent setFont:[UIFont fontWithName:@"Helvetica" size:14.0f]];
    [lblContent setText:XCLocalized(@"cameraName")];
    _txtView = [[UITextView alloc] initWithFrame:Rect(10,lblContent.frame.origin.y+30, kScreenWidth-20, 160)];
    [self.view addSubview:_txtView];
    _txtView.delegate = self;
    [_txtView setBackgroundColor:RGB(244, 244, 244)];
    [_txtView setFont:[UIFont fontWithName:@"Helvetica" size:14.0f]];
}


-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
-(void)updateDevName
{
    NSString *strInfo = [_txtView text];
    if ([strInfo isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"cameranull")];
        return ;
    }
    if ([strInfo length]>=kUSER_INFO_MAX_LENGTH)
    {
        [self.view makeToast:XCLocalized(@"cameraLess")];
        return ;
    }
    [ProgressHUD show:XCLocalized(@"Modify")];
    if(_updNameService==nil)
    {
        _updNameService = [[UpdNameService alloc] init];
    }
    __weak UpdDevNameViewController *__weakSelf = self;
    _updNameService.httpBlock = ^(int nStauts)
    {
        [ProgressHUD dismiss];
        NSString *strMsg = nil;
        switch (nStauts)
        {
            case 1:
                strMsg = XCLocalized(@"updateOK");
                break;
            case 74:
                strMsg = XCLocalized(@"ServerException");
                break;
            default:
                strMsg = XCLocalized(@"updateTimeOut");
                break;
        }
        [__weakSelf.view makeToast:strMsg duration:3.0 position:@"center" title:XCLocalized(@"Modify")];
        if (nStauts ==1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_DEVICE_LIST_VC object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_DEV_NAME_VC object:__weakSelf.strName];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                   {
                       [__weakSelf navBack];
                   });
        }
    };
    _strName = [strInfo stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    [_updNameService requestUpdName:_strNo name:_strName];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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

-(void)setDevInfo:(NSString*)strNo
{
    _strNo = strNo;
}
@end
