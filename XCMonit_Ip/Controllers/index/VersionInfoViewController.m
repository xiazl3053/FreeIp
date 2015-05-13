//
//  VersionInfoViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/20.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "VersionInfoViewController.h"
#import "CustomNaviBarView.h"
#import "ProgressHUD.h"
#import "NSDate+convenience.h"
#import "VersionCheckService.h"
#import "Toast+UIView.h"

@interface VersionInfoViewController ()<UIAlertViewDelegate>
{
    VersionCheckService *versionService;
    
}
@property (nonatomic,strong) UIImageView *imgView;

@property (nonatomic,strong) UILabel *lblInfo;
@end

@implementation VersionInfoViewController


-(void)dealloc
{
    _imgView.image = nil;
    [_imgView  removeFromSuperview];
    _imgView = nil;
    [_lblInfo removeFromSuperview];
    _lblInfo = nil;
    DLog(@"versionInfo dealloc");
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}
-(void)initUI
{
    [self setNaviBarTitle:XCLocalized(@"versionInfo")];    // 设置标题
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];       // 若不需要默认的返回按钮，直接赋nil
    [self setNaviBarRightBtn:nil];
}
-(void)initBodyView
{
    _imgView = [[UIImageView alloc] initWithFrame:Rect(60, [CustomNaviBarView barSize].height+50, kScreenWidth-120, 200)];
    _imgView.contentMode = UIViewContentModeScaleAspectFit;
    _imgView.image = [UIImage imageNamed:@"logo_info"];
    [self.view addSubview:_imgView];
    NSString *strVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    DLog(@"strVersion:%@",strVersion);
    _lblInfo = [[UILabel alloc] initWithFrame:Rect(0, [CustomNaviBarView barSize].height+270, kScreenWidth, 30)];
    NSString *strInfo = [NSString stringWithFormat:@"V%@",strVersion];
    [_lblInfo setText:strInfo];
    [_lblInfo setFont:[UIFont fontWithName:@"Helvetica" size:20.0f]];
    [_lblInfo setTextAlignment:NSTextAlignmentCenter];
    
    [self.view  addSubview:_lblInfo];
    
    UIButton *btnCheck = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [btnCheck setTitle:XCLocalized(@"versionCheck") forState:UIControlStateNormal];
    [btnCheck setBackgroundImage:[UIImage imageNamed:@"delete_btn"] forState:UIControlStateNormal];
    [btnCheck setBackgroundImage:[UIImage imageNamed:@"delete_btn_onpress"] forState:UIControlStateHighlighted];
    [self.view addSubview:btnCheck];
    
    btnCheck.frame = Rect(50, _lblInfo.frame.origin.y+60, kScreenWidth-100, 45);
    [btnCheck addTarget:self action:@selector(queryVersion) forControlEvents:UIControlEventTouchUpInside];
}

-(void)queryVersion
{
    if(versionService==nil)
    {
        versionService = [[VersionCheckService alloc] init];
    }
    __weak VersionInfoViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [__self.view makeToastActivity];
    });
    versionService.httpBlock = ^(NSString *strVersion)
    {
        DLog(@"strVersion:%@",strVersion);
        [__self.view hideToastActivity];
        if([strVersion isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [__self.view makeToast:XCLocalized(@"versionLaster")];
            });
        }
        else
        {
            __strong VersionInfoViewController *__strongSelf = __self;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:XCLocalized(@"versionUpdate") delegate:__strongSelf cancelButtonTitle:XCLocalized(@"cancel")
                                                      otherButtonTitles:XCLocalized(@"confirm"), nil];
                alert.tag = 100;
                [alert show];
            });
        }
    };
    __weak VersionCheckService *__versionCheck = versionService;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0*NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
        [__versionCheck requestVersion];
    });
    
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100) {
        switch (buttonIndex)
        {
            case 1:
                [self updateVersion];
                break;
            default:
                break;
        }
    }
}

-(void)updateVersion
{
   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/cn/app/freeip/id898690336?mt=8"]];
}

-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    [self initBodyView];
}

- (void)didReceiveMemoryWarning
{
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
