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

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];

    //IQKeyboardManager
    [[IQKeyboardManager sharedManager] setEnable:YES];
    
    LoginViewController *loginView = [[LoginViewController alloc] init];
    
    self.window.rootViewController = loginView;
    
    return YES;
}
- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskAll;
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    //应用程序挂起的时候
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_ENTER_BACK object:nil];
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [NSThread sleepForTimeInterval:5.0f];
    });
    
    DLog(@"程序挂起");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DLog(@"进入后台");
 //   [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_ENTER_BACK object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_APPLITION_ENTER_FOREG object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DLog(@"返回后台");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DLog(@"程序结束");
}

@end
