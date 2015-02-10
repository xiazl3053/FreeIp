 //
//  DeviceViewController.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-20.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "DeviceViewController.h"
#import "CustomNaviBarView.h"
#import "AddDevViewController.h"
#import "DeviceInfoDb.h"
#import "DeviceCell.h"
#import "UtilsMacro.h"
#import "DevModel.h"
#import "PlayP2PViewController.h"
#import "XCNotification.h"
#import "MJRefresh.h"
#import "DeviceService.h"
#import "DeviceInfoModel.h"
#import "DevInfoViewController.h"
#import "Toast+UIView.h"
#import "IndexViewController.h"
#import "QrcodeViewController.h"
#import "NSMutableArray+convenience.h"
#import "DecodeJson.h"

#define DeviceInfoIdentifier  @"DeviceInfoIdentifier"
#define kRequestDeviceNumber   10
@interface DeviceViewController ()<DeviceDelegate>
{
   
}
@property (nonatomic,strong) DeviceService *devService;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,assign) NSInteger nCount;
@property (nonatomic,assign) NSInteger nTimeOut;
@end
@implementation DeviceViewController

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_tableView removeFromSuperview];
    [_array removeAllObjects];
    _array = nil;
    _tableView = nil;
    _devService = nil;
    _tableView = nil;
    _array = nil;
    DLog(@"deviceview dealloc");
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _devService = [[DeviceService alloc] init];
        _array = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNaviBarTitle:XCLocalized(@"deviceList")];
    [self setNaviBarLeftBtn:nil];
    UIButton *btnAdd = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnAdd setImage:[UIImage imageNamed:@"add_icon"] forState:UIControlStateNormal];
    [btnAdd addTarget:self action:@selector(addDevice) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarRightBtn:btnAdd];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth,
                                        kScreenHeight+HEIGHT_MENU_VIEW(20, 0)-XC_TAB_BAR_HEIGHT-[CustomNaviBarView barSize].height)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _nTimeOut = 0;

    [_tableView addHeaderWithTarget:self action:@selector(headerRereshing)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(headerRereshing) name:NSUPDATE_DEVICE_LIST_VC object:nil];
  
    [self.view setUserInteractionEnabled:YES];
    
}

-(void)enter_Home
{
    [[IndexViewController sharedIndexViewController] setIndexViewController:2];
}
-(void)enter_More
{
    [[IndexViewController sharedIndexViewController] setIndexViewController:0];
}

-(void)updateUIData
{
    [_tableView reloadData];
    if (_array.count==0)
    {
        [[_tableView viewWithTag:1001] removeFromSuperview];
        [[_tableView viewWithTag:1002] removeFromSuperview];
        [[_tableView viewWithTag:1003] removeFromSuperview];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:Rect((kScreenWidth-99)/2, 132.5, 99, 70)];
        imgView.image=[UIImage imageNamed:@"no_device"];
        [_tableView addSubview:imgView];
        imgView.tag = 1001;
        
        UILabel *lblInfo = [[UILabel alloc] initWithFrame:Rect(0, imgView.frame.origin.y+imgView.frame.size.height+20.5, kScreenWidth, 39)];
        [lblInfo setText:XCLocalized(@"noDevice")];
        [lblInfo setTextAlignment:NSTextAlignmentCenter];
        [_tableView addSubview:lblInfo];
        [lblInfo setTextColor:RGB(208, 208, 208)];
        [lblInfo setFont:[UIFont fontWithName:@"Helvetica" size:14.f]];
        
        lblInfo.tag = 1002;
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:XCLocalized(@"AddCamera") forState:UIControlStateNormal];
        btn.frame = Rect(46, lblInfo.frame.origin.y+lblInfo.frame.size.height+31,kScreenWidth-92,45);
        [btn setBackgroundImage:[UIImage imageNamed:@"delete_btn"] forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageNamed:@"delete_btn_onpress"] forState:UIControlStateHighlighted];
        [_tableView addSubview:btn];
        btn.tag = 1003;
        [btn addTarget:self action:@selector(addDevice) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [[_tableView viewWithTag:1001] removeFromSuperview];
        [[_tableView viewWithTag:1002] removeFromSuperview];
        [[_tableView viewWithTag:1003] removeFromSuperview];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUIData];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}
#pragma mark 下拉更新
- (void)headerRereshing
{
    DLog(@"下拉");
    __weak DeviceViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf initData:0];
    });
}
#pragma mark 加载更多
- (void)footerBeginRefreshing
{
    __weak DeviceViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf initMoreData:0];

    });
}
-(void)initMoreData:(NSInteger)nIndex
{
    __weak DeviceViewController *__weakSelf = self;
    __block NSInteger nForCount = 0;

    _devService.httpDeviceBlock = ^(DeviceInfoModel *devInfo,NSInteger nCount)
    {
        if (nCount == -1)
        {
            [__weakSelf.view makeToast:XCLocalized(@"deviceinfotimeout")];
            [__weakSelf.tableView footerEndRefreshing];
        }
        if (nCount==0)
        {
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [__weakSelf.tableView footerEndRefreshing];
                [__weakSelf.view makeToast:XCLocalized(@"devDone")];
            });
            return ;
        }
        if (devInfo)
        {
            [__weakSelf.array addObject:devInfo];
            nForCount ++;
            __weakSelf.nCount++;
        }
        if (nCount==nForCount)
        {
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [__weakSelf.tableView reloadData];
                [__weakSelf.tableView footerEndRefreshing];
                [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_HOME_TABLEVIEW_VC object:__weakSelf.array];
            });
        }
    };
    [_devService queryDeviceNumber];
}
-(void)initData:(NSInteger)nIndex
{
    __weak DeviceViewController *__weakSelf = self;
    __block NSInteger nForCount = 0;
    __block NSMutableArray *aryList = [[NSMutableArray alloc] init];
    _nCount = 0;
    _devService.httpDeviceBlock = ^(DeviceInfoModel *devInfo,NSInteger nCount)
    {
        if (nCount == -1)
        {
            [__weakSelf.view makeToast:XCLocalized(@"deviceinfotimeout")];
            [__weakSelf.tableView headerEndRefreshing];
            DLog(@"获取设备信息超时");
            [[NSNotificationCenter defaultCenter] postNotificationName:NS_GET_DEVICE_LIST_VC object:nil];
            if (__weakSelf.nTimeOut <=2) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^{[__weakSelf initData:0];});
            }
            __weakSelf.nTimeOut ++;
            return ;
        }
        if (devInfo)
        {
            [aryList addObject:devInfo];
            nForCount ++;
            __weakSelf.nCount++;
        }
        if (nCount==nForCount)
        {
            [__weakSelf.array removeAllObjects];
            [__weakSelf.array addObjectsFromArray:aryList];
            [aryList removeAllObjects];
            aryList = nil;
            [__weakSelf arrayInfo];
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_HOME_TABLEVIEW_VC object:__weakSelf.array];
                [__weakSelf updateUIData];
                [__weakSelf.tableView headerEndRefreshing];
            });
            if(nCount>0)
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [__weakSelf.view makeToast:XCLocalized(@"devDone")];
                });
            }
            __weakSelf.nTimeOut = 0;
        }
    };
    [_devService queryDeviceNumber];
}

-(void)arrayInfo
{
    NSArray *array = [_array sortedArrayUsingComparator:cmptr];
    [_array removeAllObjects];
    [_array addObjectsFromArray:array];
}

NSComparator cmptr = ^(id obj1, id obj2)
{
    DeviceInfoModel *dev1 = obj1;
    DeviceInfoModel *dev2 = obj2;
    if (dev1.iDevOnline < dev2.iDevOnline) {
        return (NSComparisonResult)NSOrderedDescending;
    }
    
    if (dev1.iDevOnline > dev2.iDevOnline) {
        return (NSComparisonResult)NSOrderedAscending;
    }
    return (NSComparisonResult)NSOrderedSame;
};

-(void)loadMoreData
{
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
 // [_tableView reloadData];
}
-(void)addDevice
{
    QrcodeViewController *qrcode = [[QrcodeViewController alloc] init];
    [self presentViewController:qrcode animated:YES completion:^{}];
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark TableVieww委托

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *myHeader = [[UIView alloc] initWithFrame:Rect(0, 0, kScreenWidth, 30)];
    [myHeader setBackgroundColor:RGB(236, 236, 236)];
    UILabel *myLabel = [[UILabel alloc] init];
    [myLabel setFrame:CGRectMake(10, 0, kScreenWidth, 30)];
    [myLabel setTag:101];
    [myLabel setBackgroundColor:[UIColor clearColor]];
    NSString *strInfo = [NSString stringWithFormat:@"%@:%d",XCLocalized(@"deviceInfo"),(int)_array.count];
    [myLabel setFont:[UIFont fontWithName:@"Helvetica" size:14.0f]];
    [myLabel setTextColor:RGB(173, 173, 173)];
    [myLabel setText:strInfo];
    
    [myHeader addSubview:myLabel]; 
    return myHeader;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:DeviceInfoIdentifier];
    if (cell==nil)
    {
        cell = [[DeviceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DeviceInfoIdentifier];
    }
    DeviceInfoModel *devModel = [_array objectAtIndex:indexPath.row];
    NSString *strDevice = [DecodeJson getDeviceTypeByType:[devModel.strDevType intValue]];
    if ([strDevice isEqualToString:@"IPC"])
    {
        [cell.imgView setImage:[UIImage imageNamed:@"device_ipc"]];
    }
    else
    {
        [cell.imgView setImage:[UIImage imageNamed:@"device_dvr"]];
    }
    cell.nStatus = devModel.iDevOnline;
    [cell setDevName:@""];
    cell.lblDevNO.text = devModel.strDevName;
    //图片暂时使用默认的
    [cell removeTap];
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeviceInfoModel *devInfo = [_array objectAtIndex:indexPath.row];
    DevInfoViewController *devInfoView = [[DevInfoViewController alloc] init];
    [devInfoView setDeviceInfoModel:devInfo];
    [self.parentViewController presentViewController:devInfoView animated:YES
                                          completion:nil];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableviewDeviceCellHeight;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *strInfo = [NSString stringWithFormat:@"%@:%lu",XCLocalized(@"deviceInfo"),(unsigned long)_array.count];
    return strInfo;
}

@end
