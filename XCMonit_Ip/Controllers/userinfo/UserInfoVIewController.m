//
//  UserInfoVIewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "UserInfoVIewController.h"
#import "UserInfoService.h"
#import "CustomNaviBarView.h"
#import "DeviceInfoCell.h"
#import "UserImageCell.h"
#import "UserInfo.h"
#import "Toast+UIView.h"

#define USER_INFO_NULL NSLocalizedString(@"NULLInfo", nil)


@interface UserInfoVIewController ()<UITableViewDelegate,UITableViewDataSource>



@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UserAllInfoModel *userAll;
@property (nonatomic,strong) UserInfoService *userServie;

@end

@implementation UserInfoVIewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)initUI
{
    [self setNaviBarTitle:nil];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth, kScreenHeight -[CustomNaviBarView barSize].height)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self initData];
    [_tableView setBackgroundColor:[UIColor whiteColor]];
}
-(void)initData
{
    if (_userServie==nil)
    {
        _userServie = [[UserInfoService alloc] init];
    }
    __weak UserInfoVIewController *weakSelf = self;
    _userServie.httpBlock = ^(UserAllInfoModel *user,int nStatus)
    {
        switch (nStatus) {
            case 1:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.userAll = user;
                    [weakSelf.tableView reloadData];
                });
            }
            break;
            default:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.view makeToast:NSLocalizedString(@"userTimeout", nil)];
                });
            }
                break;
        }
    };
    [_userServie requestUserInfo];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strUserInfo = @"XCUserAllInfo";
    static NSString *strImageInfo = @"xcUserImageCell";

    if (indexPath.row == 1)
    {
        UserImageCell *cell = [tableView dequeueReusableCellWithIdentifier:strImageInfo];
        if (cell==nil)
        {
            cell = [[UserImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strImageInfo];
        }
        [cell.lblDevInfo setText:NSLocalizedString(@"Useravatar", nil)];
        [cell setImageInfo:_userAll.strFile];
        return cell;
    }else
    {
        DeviceInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:strUserInfo];
        if (cell==nil)
        {
            cell = [[DeviceInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strUserInfo];
        }
        switch (indexPath.row) {
            case 0:
            {
                cell.lblDevInfo.text = NSLocalizedString(@"Nickname", nil);
                cell.lblContext.text = [UserInfo sharedUserInfo].strUser;
            }
            break;
            case 2:
            {
                cell.lblDevInfo.text = NSLocalizedString(@"RealName", nil);
                cell.lblContext.text = [_userAll.strName isEqualToString:@""] ? USER_INFO_NULL : _userAll.strName;
            }
            break;
            case 3:
            {
                cell.lblDevInfo.text = NSLocalizedString(@"email", nil);
                cell.lblContext.text = [_userAll.strEmail isEqualToString:@""] ? USER_INFO_NULL : _userAll.strEmail;
            }
            break;
            case 4:
            {
                cell.lblDevInfo.text = NSLocalizedString(@"mobile", nil);
                cell.lblContext.text = [_userAll.strMobile isEqualToString:@""] ? USER_INFO_NULL : _userAll.strMobile;
            }
            break;
            case 5:
            {
                cell.lblDevInfo.text = NSLocalizedString(@"userType", nil);
                cell.lblContext.text = NSLocalizedString(@"familyType",nil);
            }
            default:
                break;
        }
        return cell;
    }
    return nil;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
#pragma mark 高
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (indexPath.row==1) {
//        return 50;
//    }
//    return 40;
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
