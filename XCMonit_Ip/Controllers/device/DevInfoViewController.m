//
//  DevInfoViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/13.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "DevInfoViewController.h"
#import "CustomNaviBarView.h"
#import "DeviceInfoModel.h"
#import "DeleteDevService.h"
#import "XCNotification.h"
#import "DeviceInfoCell.h"
#import "Toast+UIView.h"
#import "DevNameCell.h"
#import "UpdDevNameViewController.h"
#import "ProgressHUD.h"
#define DEVICEINFOCELLID @"DEVICEINFOCELLID"

@interface DevInfoViewController ()<UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate>
{
    DeviceInfoModel *_devInfo;
}

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSArray *arrayHeader;

@end

@implementation DevInfoViewController

-(void)setDeviceInfoModel:(DeviceInfoModel*)devInfo
{
    _devInfo = devInfo;
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
    [self setNaviBarTitle:NSLocalizedString(@"devDetails","DeviceDetails")];
    [self setNaviBarLeftBtn:nil];
    [self setNaviBarRightBtn:nil];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_H" target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    
    CGRect frame = CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth, kScreenHeight);
    _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    //    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _arrayHeader = [[NSArray alloc] initWithObjects:@"帮助",@"关于",nil];
    [self.view addSubview:_tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDevName:) name:NSUPDATE_DEV_NAME_VC object:nil];
    // Do any additional setup after loading the view.
}
-(void)updateDevName:(NSNotification*)notification
{
    NSString *strDevName = [notification object];
    _devInfo.strDevName = strDevName;
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


#pragma mark data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger integar = 0;
    switch (section) {
        case 0:
            integar = [_arrayHeader count];
            break;
        case 1:
            integar = 2;
            break;
        case 2:
            integar = 1;
            break;
    }
    return integar;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    DevNameCell *cell = [_tableView dequeueReusableCellWithIdentifier:DEVICEINFOCELLID];
                    if (cell==nil)
                    {
                        cell = [[DevNameCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DEVICEINFOCELLID];
                    }
                    NSString *strImage = _devInfo.iDevOnline ? @"deviceOn" : @"deviceOff";
                    [cell setDevInfo:strImage name:_devInfo.strDevName];
                    return cell;
                }
                break;
                case 1:
                {
                    
                    NSString *strStatus = nil;
                    if(_devInfo.iDevOnline ==0)
                    {
                        strStatus = NSLocalizedString(@"offline","offline");
                    }else
                    {
                        strStatus = NSLocalizedString(@"online","online");
                    }
                    DeviceInfoCell *cell = [self createDeviceInfoCell:NSLocalizedString(@"statu","device status") context:strStatus];
                    return cell;
                }
                break;
            }
        }
        break;
        case 1:
        {
            DeviceInfoCell *cell = nil;
            switch (indexPath.row)
            {
                case 0:
                {
                    cell = [self createDeviceInfoCell:NSLocalizedString(@"type","device type") context:_devInfo.strDevType];
                    
                }
                break;
                case 1:
                {
                    cell = [self createDeviceInfoCell:NSLocalizedString(@"devNO","devNO") context:_devInfo.strDevNO];
                }
                break;
                   
            }
            return cell;
        }
        break;
        case 2:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DEVICEINFOCELLID];
            if (cell==nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DEVICEINFOCELLID];
            }
            [cell.textLabel setFont:[UIFont systemFontOfSize:16.0f]];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
            cell.textLabel.text = NSLocalizedString(@"devDel","devDel");
            return cell;
        }
        break;
    }
    return nil;
}
-(DeviceInfoCell*)createDeviceInfoCell:(NSString*)strInfo context:(NSString*)strContext;
{
    DeviceInfoCell *cell = [_tableView dequeueReusableCellWithIdentifier:DEVICEINFOCELLID];
    if (cell==nil) {
        cell = [[DeviceInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DEVICEINFOCELLID];
    }
    [cell setDevInfo:strInfo context:strContext];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        return 51;
    }
    return 44;
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}
#pragma mark 选择不同行的事件
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            if (indexPath.row==0)//修改DevName
            {
                UpdDevNameViewController *updView = [[UpdDevNameViewController alloc] init];
                [updView setDevInfo:_devInfo.strDevNO];
                [self presentViewController:updView animated:YES completion:^{}];
            }
        }
        break;
        case 1:
        {

        }
        break;
        case 2:
        {
            //点击的是删除设备
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"delDeviceQuq", "delete device request") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", "cancel") otherButtonTitles:NSLocalizedString(@"confirm", "confirm"), nil];//confirm
            alert.tag = 100;
            [alert show];
        }
        break;

    }
}
-(void)clickDeleteDevice
{
    DeleteDevService *delete = [[DeleteDevService alloc] init];
    __weak DevInfoViewController *__weakSelf = self;
    [ProgressHUD show:@"删除设备"];
    delete.httpDelDevBlock = ^(int nStatus)
    {
        [ProgressHUD dismiss];
        NSString *strMsg = nil;
        switch (nStatus)
        {
            case 1:
                strMsg = @"删除成功";
                break;
            case 54:
                strMsg = @"设备信息错误";
                break;
            case 56:
                strMsg = @"设备序列号错误";
                break ;
            case -999:
                strMsg = @"服务器异常";
                break;
            default:
                strMsg = @"服务器错误";
                break;
        }
        [__weakSelf.view makeToast:strMsg duration:3.0 position:@"center" title:@"删除设备"];
        if (nStatus ==1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_DEVICE_LIST_VC object:nil];
            [__weakSelf navBack];
        }
    };
    [delete requestDelDevInfo:_devInfo.strDevNO auth:@""];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100) {
        switch (buttonIndex)
        {
            case 1:
                [self clickDeleteDevice];
                break;
            default:
                break;
        }
    }
}

-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
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

@end
