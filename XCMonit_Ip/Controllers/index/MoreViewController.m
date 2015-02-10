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

@interface MoreViewController ()<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>
{
    UISwipeGestureRecognizer *leftSwipe;
}

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSArray *arrayHeader;

@end

@implementation MoreViewController

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
    [self setNaviBarTitle:NSLocalizedString(@"more", "more")];
    [self setNaviBarLeftBtn:nil];
    [self setNaviBarRightBtn:nil];
    CGRect frame = CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth,
                            kScreenHeight+HEIGHT_MENU_VIEW(20, 0)-44-[CustomNaviBarView barSize].height);
    _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setBackgroundColor:[UIColor whiteColor]];

    
    _arrayHeader = [[NSArray alloc] initWithObjects:NSLocalizedString(@"picture", "picture"),NSLocalizedString(@"userinfo", "userinfo"),
                    NSLocalizedString(@"version", "version"),NSLocalizedString(@"aboutus", "aboutus"),nil];
    [self.view addSubview:_tableView];
    
    leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(enter_ListView)];
    [leftSwipe setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view setUserInteractionEnabled:YES];
    [self.view addGestureRecognizer:leftSwipe];
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
    NSInteger integar = 0;
    switch (section) {
        case 0:
            integar = [_arrayHeader count];
            break;
        case 1:
            integar = 1;
            break;
    }
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
        case 0:
        {
            cell.textLabel.text = [_arrayHeader objectAtIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator ;
        }
        break;
        case 1:
        {
            
            cell.textLabel.text = NSLocalizedString(@"logout", "logout");
        }
    }
    
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

#pragma mark tableviewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                {
                    ImageViewController *image =[[ImageViewController alloc] init];
                    [self.parentViewController presentViewController:image animated:YES completion:nil];
                }
                break;
                case 1:
                {
                    UserInfoVIewController *userView = [[UserInfoVIewController alloc] init];
                    [self.parentViewController presentViewController:userView animated:YES completion:^{}];
                }
                break;
                case 2:
                {
                    
                }
                break;
            }
        }
        break;
        case 1:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Remind",nil) message:NSLocalizedString(@"logoutRemind",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", "cancel") otherButtonTitles:NSLocalizedString(@"logout","logout"), nil];
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
-(void)exitApplication
{
    
    [self.parentViewController dismissViewControllerAnimated:YES completion:^{
        [[IndexViewController sharedIndexViewController] closeIndexView];
    }];

}


//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    
//    NSString *strInfo = nil;
//    switch (section) {
//        case 0:
//            strInfo = @"1111";
//            break;
//        case 1:
//            strInfo = @"2222";
//            break;
//    }
//    return strInfo;
//}

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
