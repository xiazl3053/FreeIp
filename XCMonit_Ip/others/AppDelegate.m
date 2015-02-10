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

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskAll;
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    //等待当前可能同步无法完成的线程结束
//    [self performSelector:@selector(willResignActive) withObject:self afterDelay:5.0f];
  //  sleep(5);
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_ENTER_BACK object:nil];
}

-(void)willResignActive
{
    //先判断应用状态
    
    //发送立即结束通知
//    [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_ENTER_BACK object:nil];
//    DLog(@"程序挂起");
}



//
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DLog(@"进入后台");
 //   [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_ENTER_BACK object:nil];
    //延长后台结束的时间
//    UIApplication *app = [UIApplication sharedApplication];
//    
//    //一个后台任务标识符
//    UIBackgroundTaskIdentifier taskID;
//    taskID = [app beginBackgroundTaskWithExpirationHandler:^{
//        //如果系统觉得我们还是运行了太久，将执行这个程序块，并停止运行应用程序
//        [app endBackgroundTask:taskID];
//    }];
//    //UIBackgroundTaskInvalid表示系统没有为我们提供额外的时候
//    if (taskID == UIBackgroundTaskInvalid) {
//        NSLog(@"Failed to start background task!");
//        return;
//    }
//    NSLog(@"Starting background task with %f seconds remaining", app.backgroundTimeRemaining);
//    [NSThread sleepForTimeInterval:10];
//    NSLog(@"Finishing background task with %f seconds remaining",app.backgroundTimeRemaining);
//    //告诉系统我们完成了
//    [app endBackgroundTask:taskID];
    
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

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_ENTER_FOREG object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DLog(@"程序返回");
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_BECOME_ACTIVE object:nil];
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DLog(@"程序结束");
}

@end
