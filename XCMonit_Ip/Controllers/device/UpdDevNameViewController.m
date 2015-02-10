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
@interface UpdDevNameViewController ()
{
    UITextView *_txtView;
}
@property (nonatomic,strong) UpdNameService *updNameService;
@property (nonatomic,copy) NSString *strNo;
@property (nonatomic,copy) NSString *strName;
@end

@implementation UpdDevNameViewController

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
    [self setNaviBarTitle:NSLocalizedString(@"updDevName", "updDevName")];
    
    UIButton *left = [CustomNaviBarView createNormalNaviBarBtnByTitle:NSLocalizedString(@"cancel", "cancel") target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:left];
    UIButton *right = [CustomNaviBarView createNormalNaviBarBtnByTitle:NSLocalizedString(@"save", "save") target:self action:@selector(updateDevName)];
    [self setNaviBarRightBtn:right];
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(10, [CustomNaviBarView barSize].height+10, 300, 16)];
    [self.view addSubview:lblContent];
    [lblContent setFont:[UIFont systemFontOfSize:14.0f]];
    [lblContent setText:NSLocalizedString(@"cameraName", "cameraName")];
    _txtView = [[UITextView alloc] initWithFrame:Rect(10,lblContent.frame.origin.y+30, 300, 160)];
    [self.view addSubview:_txtView];
    [_txtView setBackgroundColor:RGB(244, 244, 244)];
    [_txtView setFont:[UIFont systemFontOfSize:14.0f]];
    
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
        [self.view makeToast:NSLocalizedString(@"cameranull", nil)];
        return ;
    }
    if ([strInfo length]>50) {
        [self.view makeToast:NSLocalizedString(@"cameraLess", nil)];
        return ;
    }
    [ProgressHUD show:NSLocalizedString(@"Modify", nil)];
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
                strMsg = NSLocalizedString(@"updateOK", nil);
                break;
            case 74:
                strMsg = NSLocalizedString(@"ServerException", nil);
                break;
            default:
                strMsg = NSLocalizedString(@"updateTimeOut", nil);
                break;
        }
        [__weakSelf.view makeToast:strMsg duration:3.0 position:@"center" title:NSLocalizedString(@"Modify", nil)];
        if (nStauts ==1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_DEVICE_LIST_VC object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_DEV_NAME_VC object:__weakSelf.strName];
            [__weakSelf navBack];
        }
    };
    _strName = strInfo;
    [_updNameService requestUpdName:_strNo name:_strName];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
-(void)setDevInfo:(NSString*)strNo
{
    _strNo = strNo;
}
@end
