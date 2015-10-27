//
//  IndexViewController.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-20.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "IndexViewController.h"
#import "XCTabBar.h"
#import "DevInfoMacro.h"
#import "HomeViewController.h"
#import "DeviceViewController.h"
#import "MoreViewController.h"
#import "DeviceService.h"
#import "DeviceInfoModel.h"
#import "XCButton.h"
#import "XCNotification.h"
#import "DeviceInfoDb.h"
#import "LoginService.h"
#import "UserModel.h"
#import "XCDecoder.h"
#import "P2PInitService.h"
#import "LoginViewController.h"
#import "UserInfo.h"
#import "UserInfoService.h"
#import "UserAllInfoModel.h"
#import "Toast+UIView.h"
#import "UserInfo.h"

#define REQUEST_DEVICE_NUMBER   10
#define SELECTED_VIEW_CONTROLLER_TAG 98456345




@interface IndexViewController ()<XCTabBarDelegate>

@property (nonatomic,strong) DeviceService *service;
@property (nonatomic,strong) XCTabBar *tabBar;
@property (nonatomic,strong) XCDecoder *decoder;
@property (nonatomic,strong) UIScrollView *scrollViewInfo;
@property (nonatomic,strong) UserInfoService *userServie;
@property (nonatomic,strong) HomeViewController *homeView;
@property (nonatomic,strong) DeviceViewController *deviceView;
@property (nonatomic,strong) MoreViewController *moreView;

@end

@implementation IndexViewController

DEFINE_SINGLETON_FOR_CLASS(IndexViewController);

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)initBody
{
    _homeView = [[HomeViewController alloc] init];
    XCTabInfo *tb1 = [[XCTabInfo alloc] initWithTabInfo:XCLocalized(@"home") normal:@"home.png" high:@"home_h.png"];
    tb1.viewController = _homeView;
    [self addChildViewController:_homeView];

    XCTabInfo *tb2 = [[XCTabInfo alloc] initWithTabInfo:XCLocalized(@"device") normal:@"set.png" high:@"set_h.png"];
    _deviceView = [[DeviceViewController alloc] init];
    tb2.viewController = _deviceView;
    [_deviceView initData:0];
    [self addChildViewController:_deviceView];
    
    if(![UserInfo sharedUserInfo].bGuess)
    {
        XCTabInfo *tb3 = [[XCTabInfo alloc] initWithTabInfo:XCLocalized(@"more") normal:@"about.png" high:@"about_h.png"];
        _moreView = [[MoreViewController alloc] init];
        tb3.viewController = _moreView;
        [self addChildViewController:_moreView];
        
        NSArray *aryItem = [[NSArray alloc] initWithObjects:tb1,tb2,tb3, nil];
        _tabBar = [[XCTabBar alloc] initWithItems:aryItem];
        _tabBar.delegate = self;
        [self.view addSubview:_tabBar];
        [_tabBar setSelectIndex:0];
    }
    else
    {
        NSArray *aryItem = [[NSArray alloc] initWithObjects:tb1, nil];
        _tabBar = [[XCTabBar alloc] initWithItems:aryItem];
        _tabBar.delegate = self;
        [self.view addSubview:_tabBar];
        [_tabBar setSelectIndex:0];
    }
    _homeView.view.tag = SELECTED_VIEW_CONTROLLER_TAG;
}
- (void)selectIndex:(UIViewController *)viewController
{
    __weak IndexViewController *__weakSelf = self;
    __weak UIViewController *__viewController = viewController;
    [UIView animateWithDuration:0.1f animations:
     ^{
         UIView *currentView = [__weakSelf.view viewWithTag:SELECTED_VIEW_CONTROLLER_TAG];
         [currentView removeFromSuperview];
         __viewController.view.frame = CGRectMake(0,0,kScreenWidth, kScreenHeight-_tabBar.frame.size.height+20);
         __viewController.view.tag = SELECTED_VIEW_CONTROLLER_TAG;
         [__weakSelf.view insertSubview:__viewController.view aboveSubview:__weakSelf.tabBar];

    }];
}
#pragma mark 设置显示的viewController
-(void)setIndexViewController:(int)nIndex
{
    [_tabBar setSelectIndex:nIndex];
}
-(void)setInit
{
    __weak IndexViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{[weakSelf initBody];});
}
#pragma mark 加载通知
- (void)viewDidLoad
{
    [super viewDidLoad];
    P2PInitService *p2pInit = [P2PInitService sharedP2PInitService];
    __weak P2PInitService *__P2PInit = p2pInit;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //替换
        [__P2PInit getIPWithHostName:XCLocalized(@"p2pserver")];
        DLog(@"解析IP:%@",__P2PInit.strAddress);
    });
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectAgain) name:NS_APPLITION_ENTER_FOREG object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enter_background) name:NS_APPLITION_ENTER_BACK object:nil];
    
    //加载用户数据
    [self initData];
}

-(void)initData
{
    if (_userServie==nil)
    {
        _userServie = [[UserInfoService alloc] init];
    }
    __weak IndexViewController *weakSelf = self;
    _userServie.httpBlock = ^(UserAllInfoModel *user,int nStatus)
    {
        switch (nStatus) {
            case 1:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UserInfo sharedUserInfo].userAllInfo = user;
                });
            }
                break;
            default:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.view makeToast:XCLocalized(@"userTimeout")];
                });
            }
            break;
        }
    };
    [_userServie requestUserInfo];
}

-(void)enter_background
{
    [[P2PInitService sharedP2PInitService] setP2PSDKNull];
    
}
-(void)connectAgain
{
    NSArray *array = [DeviceInfoDb queryUserInfo];
    if (array.count>0) {
        UserModel *userModel = [array objectAtIndex:0];
        LoginService *loginService = [[LoginService alloc] init];
        loginService.httpBlock = ^(LoginInfo *login,int nstatus)
        {
            DLog(@"重新登录结果:%d",nstatus);
        };
        [loginService connectionHttpLogin:userModel.strUser pwd:userModel.strPwd];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

-(void)closeIndexView
{
    for (UIViewController *viewControl in self.childViewControllers)
    {
        [viewControl removeFromParentViewController];
    }
    for (UIView *view in _tabBar.subviews) {
        [view removeFromSuperview];
    }
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
    _tabBar = nil;
    _homeView = nil;
    _deviceView = nil;
    _userServie = nil;
    _decoder = nil;
    _scrollViewInfo = nil;
    _moreView = nil;
}

-(void)dealloc
{
    DLog(@"indexShare dealloc");
}



@end
