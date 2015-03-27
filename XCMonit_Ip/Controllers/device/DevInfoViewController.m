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
#import "IndexViewController.h"
#import "ProgressHUD.h"
#import "DecodeJson.h"
#import "MBProgressHUD.h"

#define DEVICEINFOCELLID @"DEVICEINFOCELLID"

@interface DevInfoViewController ()<UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate>
{
    DeviceInfoModel *_devInfo;
}
@property (nonatomic,assign) BOOL bTrue;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSArray *arrayHeader;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) UIButton *btnDel;
@property (nonatomic,strong) DeleteDevService *delete;// = [[DeleteDevService alloc] init];
@property (nonatomic,strong) MBProgressHUD *mbHUD;
@end

@implementation DevInfoViewController

-(void)dealloc
{
    [_mbHUD removeFromSuperview];
    _mbHUD = nil;
    [_tableView removeFromSuperview];
    _tableView = nil;
    [_imgView removeFromSuperview];
    _imgView = nil;
    [_btnDel removeFromSuperview];
    _btnDel = nil;
    _delete = nil;
    
    _devInfo = nil;
    
    DLog(@"devInfo view dealloc");
}

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
    [self setNaviBarTitle:XCLocalized(@"devDetails")];
    [self setNaviBarRightBtn:nil];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateHighlighted];
    [btn addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarLeftBtn:btn];
    _delete = [[DeleteDevService alloc] init];
    _imgView = [[UIImageView alloc] initWithFrame:Rect(0, [CustomNaviBarView barSize].height, kScreenWidth, 137)];
    [self.view addSubview:_imgView];
    _bTrue = YES;
    [self.view setBackgroundColor:RGB(247, 247, 247)];
    
    if ([_devInfo.strDevType integerValue]<=2000)
    {
        [_imgView setImage:[UIImage imageNamed:@"ipc_big"]];
    }
    else
    {
        [_imgView setImage:[UIImage imageNamed:@"dvr_big"]];
    }
    
    CGRect frame = CGRectMake(0, [CustomNaviBarView barSize].height+139, kScreenWidth, 44.5*4);
    _tableView = [[UITableView alloc] initWithFrame:frame];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDevName:) name:NSUPDATE_DEV_NAME_VC object:nil];
    
    // Do any additional setup after loading the view.
    _btnDel = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnDel setTitle:XCLocalized(@"RecordDelete") forState:UIControlStateNormal];
    [_btnDel setBackgroundImage:[UIImage imageNamed:@"delete_btn"] forState:UIControlStateNormal];
    [_btnDel setBackgroundImage:[UIImage imageNamed:@"delete_btn_onpress"] forState:UIControlStateHighlighted];
    
    _btnDel.frame = Rect(kScreenWidth/2.0-276/2,[CustomNaviBarView barSize].height+149+44.5*4+20 , 276, 43);
    [self.view addSubview:_btnDel];
    
    [_btnDel addTarget:self action:@selector(deleteAlert) forControlEvents:UIControlEventTouchUpInside];
    
    _mbHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_mbHUD];
    [self.view bringSubviewToFront:_mbHUD];

    _mbHUD.labelText = XCLocalized(@"deleteDevice");
    
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
    return 4;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strDeviceId = @"XCDeviceIdentifier";
    DeviceInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:strDeviceId];
    if (cell==nil)
    {
        cell = [[DeviceInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strDeviceId];
    }
    switch (indexPath.row)
    {
        case 0:
        {
            cell.lblDevInfo.text = XCLocalized(@"devName_info");
            cell.lblContext.text = _devInfo.strDevName;
            cell.lblContext.frame = CGRectMake(kScreenWidth-170, 44.5/2-10, 140, 20);
            [cell addView:0 height:0];
            [cell addView:20 height:43];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
        break;
        case 1:
        {
            
            NSString *strStatus = nil;
            if(_devInfo.iDevOnline ==0)
            {
                strStatus = XCLocalized(@"offline");
            }else
            {
                strStatus = XCLocalized(@"online");
            }
            
            cell.lblDevInfo.text = XCLocalized(@"statu");//9843512744925
            cell.lblContext.text = strStatus;
            [cell addView:20 height:43];
            return cell;
        }
            break;
        case 2:
        {
            int nType = [_devInfo.strDevType intValue];
            
            NSString *strType = [DecodeJson getDeviceTypeByType:nType];

            cell.lblDevInfo.text = XCLocalized(@"type");
            cell.lblContext.text = strType;
            [cell addView:20 height:43];
            return cell;
        }
        break;
        case 3:
        {
            cell.lblDevInfo.text = XCLocalized(@"devNO");
            cell.lblContext.text = _devInfo.strDevNO;
            [cell addView:0 height:43];
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
    return 44.5;
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
            
        }
        break;

    }
}

-(void)deleteAlert
{
    //点击的是删除设备
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:XCLocalized(@"delDeviceQuq") message:nil delegate:self cancelButtonTitle:XCLocalized(@"cancel") otherButtonTitles:XCLocalized(@"confirm"), nil];//confirm
    alert.tag = 100;
    [alert show];
}

-(void)clickDeleteDevice
{

    __weak DevInfoViewController *__weakSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__weakSelf.mbHUD show:YES];
    });
    _delete.httpDelDevBlock = ^(int nStatus)
    {
        NSString *strMsg = nil;
        switch (nStatus)
        {
            case 1:
                strMsg = XCLocalized(@"deleteDeviceOK");
                break;
            case 54:
                strMsg = XCLocalized(@"deleteDeviceFail");
                break;
            default:
                strMsg = XCLocalized(@"deleteDeviceFail_server");
                break;
        }
        __weakSelf.bTrue = YES;
        
       dispatch_async(dispatch_get_main_queue(),
       ^{
           [__weakSelf.mbHUD hide:YES];
       });
        [__weakSelf.view makeToast:strMsg duration:2.0 position:@"center"];
        if (nStatus ==1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_DEVICE_LIST_VC object:nil];
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.6 * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
            {
               [__weakSelf navBack];
            });

        }
    };
    _bTrue = NO;
    [_delete requestDelDevInfo:_devInfo.strDevNO auth:@""];
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
    if (!_bTrue)
    {
        return;
    }
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
