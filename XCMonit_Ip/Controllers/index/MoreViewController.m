//
//  MoreViewController.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-20.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "MoreViewController.h"
#import "CustomNaviBarView.h"
#import "ImageViewController.h"
#import "LoginViewController.h"
#import "IndexViewController.h"
#import "UserInfoVIewController.h"
#import "VersionInfoViewController.h"
#import "UserInfo.h"
#import "UserAllInfoModel.h"
#import "Toast+UIView.h"
#import "DeviceInfoDb.h"
#import "HelpViewController.h"

@interface MoreViewController ()<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>
{
    UISwipeGestureRecognizer *leftSwipe;
}

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSArray *arrayHeader;

@end

@implementation MoreViewController

-(void)dealloc
{
    DLog(@"More View dealloc!");
    [_tableView removeFromSuperview];
    _tableView = nil;
}

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
    [super viewDidLoad];
    [self setNaviBarTitle:XCLocalized(@"more")];
    [self setNaviBarLeftBtn:nil];
    [self setNaviBarRightBtn:nil];
    CGRect frame = CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth,
                            kScreenHeight+HEIGHT_MENU_VIEW(20, 0)-XC_TAB_BAR_HEIGHT-[CustomNaviBarView barSize].height);
    _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setBackgroundColor:[UIColor whiteColor]];
    _tableView.backgroundColor = RGB(236, 236, 236);
    
    _arrayHeader = [[NSArray alloc] initWithObjects:XCLocalized(@"picture"),XCLocalized(@"userinfo"),
                    XCLocalized(@"version"),XCLocalized(@"aboutus"),nil];
    [self.view addSubview:_tableView];

}
-(void)enter_ListView
{
    [[IndexViewController sharedIndexViewController] setIndexViewController:1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger integar = 1;
    return integar;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strMoreIdenti = @"XCTableViewIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:strMoreIdenti];
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strMoreIdenti];
        
    }
    switch (indexPath.section)
    {
        case 0://用户信息
        {
            [cell.imageView setImage:[UIImage imageNamed:@"more_user"]];
            cell.textLabel.text = XCLocalized(@"userinfo");
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
            cell.textLabel.textColor = RGB(48, 48, 48);
        }
        break;
        case 1://图像内容
        {
            cell.imageView.image = [UIImage imageNamed:@"more_pic"];
            cell.textLabel.text = XCLocalized(@"picture");
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
            cell.textLabel.textColor = RGB(48, 48, 48);
        }
            break;
        case 2:
        {
            cell.imageView.image = [UIImage imageNamed:@"more_version"];
            cell.textLabel.text = XCLocalized(@"version");
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
            cell.textLabel.textColor = RGB(48, 48, 48);
        }
        break;
        case 3:
        {
            cell.imageView.image = [UIImage imageNamed:@"more_help"];
            cell.textLabel.text = XCLocalized(@"help");
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
            cell.textLabel.textColor = RGB(48, 48, 48);
        }
        break;
        case 4:
        {
            cell.imageView.image = [UIImage imageNamed:@"more_exit"];
            cell.textLabel.text = XCLocalized(@"logout");
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
            cell.textLabel.textColor = RGB(48, 48, 48);
        }
        break;
    }
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

#pragma mark tableviewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0://用户信息
        {
            UserInfoVIewController *userView = [[UserInfoVIewController alloc] init];
            [self.parentViewController presentViewController:userView animated:YES completion:^{}];
        }
        break;
        case 1://图像内容
        {
            ImageViewController *image =[[ImageViewController alloc] init];
            [self.parentViewController presentViewController:image animated:YES completion:nil];
        }
        break;
        case 2://查看版本,帮助
        {

                VersionInfoViewController *versionView = [[VersionInfoViewController alloc] init];
                [self.parentViewController presentViewController:versionView animated:YES completion:^{}];
        }
        break;
        case 3:
        {
            //帮助页
            HelpViewController *help = [[HelpViewController alloc] init];
            [self.parentViewController presentViewController:help animated:YES completion:nil];
        }
        break;
        case 4:
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:XCLocalized(@"Remind") message:XCLocalized(@"logoutRemind") delegate:self cancelButtonTitle:XCLocalized(@"cancel") otherButtonTitles:XCLocalized(@"logout"), nil];
                alert.tag = 1050;
                [alert show];
            }
        break;
    }
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag==1050) {
        switch (buttonIndex) {
            case 1:
            {
                [self exitApplication];
            }
            break;
            default:
                break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 47;
}

-(void)exitApplication
{
    [DeviceInfoDb updateLogin:0];
    [self.parentViewController dismissViewControllerAnimated:YES completion:
    ^{
        [[IndexViewController sharedIndexViewController] closeIndexView];
    }];

}


@end
