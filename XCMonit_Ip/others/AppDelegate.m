//
//  AppDelegate.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-13.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//
#import "AppDelegate.h"
#import "LoginViewController.h"
#import "IndexViewController.h"
#import "HomeViewController.h"
#import "IQKeyboardManager.h"
#import "IQSegmentedNextPrevious.h"
#import "XCNotification.h"
#import "RecordDb.h"
#import "Reachability.h"
#import "ProgressHUD.h"
#import "Toast+UIView.h"

@interface AppDelegate()
{
    BOOL bStatus;
    BOOL bGGLogin;
}

@property (nonatomic,unsafe_unretained) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic,strong) NSTimer *myTimer;

@end


@implementation AppDelegate


typedef struct testSturct
{
    unsigned int delegateWillRotate:1;
    unsigned int delegateDidRotate:1;
    unsigned int delegateWillAnimateFirstHalf:1;
    unsigned int delegateDidAnimationFirstHalf:1;
    unsigned int delegateWillAnimateSecondHalf:1;
    unsigned int autorotatesToPortrait:1;
    unsigned int autorotatesToPortraitUpsideDown:1;
    unsigned int autorotatesToLandscapeLeft4:1;
//    unsigned int autorotatesToLandscapeRight:1;
}testSturct;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    
    struct sigaction sa;
    sa.sa_handler = SIG_IGN;
    sigaction(SIGPIPE,&sa,0);
    
    NSLog(@"testSturct:%li",sizeof(testSturct));
    
    //初始化
    [RecordDb initRecordInfo];

    [[IQKeyboardManager sharedManager] setEnable:YES];
    sleep(2);
    LoginViewController *loginView = [[LoginViewController alloc] init];
    
    self.window.rootViewController = loginView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name: kReachabilityChangedNotification
                                               object: nil];
    //检测是否能连接到freeip的服务器
    hostReach = [Reachability reachabilityWithHostName:@"www.freeip.com"];
    [hostReach startNotifier];
    return YES;
}

-(void)reachabilityChanged:(NSNotification *)note
{
    Reachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus status = [curReach currentReachabilityStatus];
    
    if (status == NotReachable)
    {
        DLog(@"网络状态:中断");
        __weak UIWindow *__windows = self.window;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__windows makeToast:XCLocalized(@"networkstatusNO")];
        });
    }
    else if(status == ReachableViaWiFi)
    {
        DLog(@"网络状态:WIFI");
        __weak UIWindow *__windows = self.window;
        dispatch_async(dispatch_get_main_queue(), ^{
            [__windows makeToast:XCLocalized(@"networkstatusWIFI")];
        });
    }
    else
    {
        __weak UIWindow *__windows = self.window;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__windows makeToast:XCLocalized(@"networkstatus3G")];
        });
    }
}

-(NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskAll;
}

-(void)setEndBackground
{
    if (bStatus)
    {
        DLog(@"等待时间不够");
        return ;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_ENTER_BACK object:nil];
    bGGLogin = YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    bStatus = NO;
    self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^(void)
    {
         [self endBackgroundTask];
    }];
    _myTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f
                                                target:self
                                              selector:@selector(timerMethod:)
                                              userInfo:nil
                                               repeats:YES];
    [self performSelector:@selector(setEndBackground) withObject:nil afterDelay:30.0f];
}

-(void)timerMethod:(NSTimer *)paramSender
{
    NSTimeInterval backgroundTimeRemaining =[[UIApplication sharedApplication] backgroundTimeRemaining];
    if (backgroundTimeRemaining == DBL_MAX)
    {
        DLog(@"Background Time Remaining = Undetermined");
    }
    else
    {
        DLog(@"Background Time Remaining = %.02f Seconds", backgroundTimeRemaining);
        if (backgroundTimeRemaining<110) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
}

-(void)endBackgroundTask
{
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    AppDelegate *weakSelf = self;
    dispatch_async(mainQueue, ^(void) {
        AppDelegate *strongSelf = weakSelf;
        if (strongSelf != nil){
            [strongSelf.myTimer invalidate];// 停止定时器
            // 每个对 beginBackgroundTaskWithExpirationHandler:方法的调用,必须要相应的调用 endBackgroundTask:方法。这样，来告诉应用程序你已经执行完成了。
            // 也就是说,我们向 iOS 要更多时间来完成一个任务,那么我们必须告诉 iOS 你什么时候能完成那个任务。
            // 也就是要告诉应用程序：“好借好还”嘛。
            // 标记指定的后台任务完成
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            // 销毁后台任务标识符
            strongSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    });
}
-(void)applicationWillEnterForeground:(UIApplication *)application
{
    
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    DLog(@"返回");
    bStatus = YES;
    [self.myTimer invalidate];
    if (bGGLogin)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_BECOME_ACTIVE object:nil];
    }
}
- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}
@end
