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
#define REQUEST_DEVICE_NUMBER   10
#define SELECTED_VIEW_CONTROLLER_TAG 98456345

@interface IndexViewController ()<XCTabBarDelegate>

@property (nonatomic,strong) DeviceService *service;
@property (nonatomic,strong) XCTabBar *tabBar;
@property (nonatomic,strong) XCDecoder *decoder;
@property (nonatomic,strong) UIScrollView *scrollViewInfo;

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
    
    HomeViewController *homeView = [[HomeViewController alloc] init];
    XCTabInfo *tb1 = [[XCTabInfo alloc] initWithTabInfo:NSLocalizedString(@"home", "home") normal:@"home.png" high:@"home_h.png"];
    tb1.viewController = homeView;
    [self addChildViewController:homeView];

    
    
    XCTabInfo *tb2 = [[XCTabInfo alloc] initWithTabInfo:NSLocalizedString(@"device", "device") normal:@"set.png" high:@"set_h.png"];
    DeviceViewController *deviceView = [[DeviceViewController alloc] init];
    tb2.viewController = deviceView;
    [deviceView initData:0];
    [self addChildViewController:deviceView];

    
    
    XCTabInfo *tb3 = [[XCTabInfo alloc] initWithTabInfo:NSLocalizedString(@"more", "more") normal:@"about.png" high:@"about_h.png"];
    MoreViewController *moreView = [[MoreViewController alloc] init];
    tb3.viewController = moreView;
    [self addChildViewController:moreView];

    
    DLog(@"%f",self.view.frame.size.height);
    NSArray *aryItem = [[NSArray alloc] initWithObjects:tb1,tb2,tb3, nil];
    _tabBar = [[XCTabBar alloc] initWithItems:aryItem];
    _tabBar.delegate = self;
    [self.view addSubview:_tabBar];
    [_tabBar setSelectIndex:0];

    homeView.view.tag = SELECTED_VIEW_CONTROLLER_TAG;
}
- (void)selectIndex:(UIViewController *)viewController
{
    __weak IndexViewController *__weakSelf = self;
    __weak UIViewController *__viewController = viewController;
    [UIView animateWithDuration:0.1f animations:
     ^{
         UIView *currentView = [__weakSelf.view viewWithTag:SELECTED_VIEW_CONTROLLER_TAG];
         [currentView removeFromSuperview];
         __viewController.view.frame = CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height-_tabBar.frame.size.height);
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
        [__P2PInit getIPWithHostName:NSLocalizedString(@"p2pserver", "p2p server")];
        DLog(@"解析IP:%@",__P2PInit.strAddress);
    });
    
    DLog(@"重新添加一次");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectAgain) name:NS_APPLITION_ENTER_FOREG object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enter_background) name:NS_APPLITION_ENTER_BACK object:nil];
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
    return YES;
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
}

-(void)dealloc
{
    DLog(@"indexShare dealloc");
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
