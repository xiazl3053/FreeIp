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

#define DeviceInfoIdentifier  @"DeviceInfoIdentifier"
#define kRequestDeviceNumber   10
@interface DeviceViewController ()<DeviceDelegate>
{
    dispatch_group_t _deviceGroup;
    UISwipeGestureRecognizer *leftSwipe;
    UISwipeGestureRecognizer *rightSwipe;
}
@property (nonatomic,strong) DeviceService *devService;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,assign) NSInteger nCount;
@property (nonatomic,assign) NSInteger nTimeOut;
@end
@implementation DeviceViewController

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
    [self setNaviBarTitle:NSLocalizedString(@"device", "device")];
    [self setNaviBarLeftBtn:nil];
    UIButton *btnAdd = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [btnAdd addTarget:self action:@selector(addDevice) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarRightBtn:btnAdd];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth,
                                        kScreenHeight+HEIGHT_MENU_VIEW(20, 0)-44-[CustomNaviBarView barSize].height)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _nTimeOut = 0;

    [_tableView addHeaderWithTarget:self action:@selector(headerRereshing)];
    
    [_tableView addFooterWithTarget:self action:@selector(footerBeginRefreshing)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(headerRereshing) name:NSUPDATE_DEVICE_LIST_VC object:nil];
    _deviceGroup = dispatch_group_create();
    
    leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(enter_Home)];
    [leftSwipe setDirection:UISwipeGestureRecognizerDirectionLeft];
    rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(enter_More)];
    [rightSwipe setDirection:UISwipeGestureRecognizerDirectionRight];
    
    [self.view addGestureRecognizer:leftSwipe];
    [self.view addGestureRecognizer:rightSwipe];
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


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}
#pragma mark 下拉更新
- (void)headerRereshing
{
    NSLog(@"下拉");
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
        [weakSelf initMoreData:weakSelf.nCount];

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
            [__weakSelf.view makeToast:NSLocalizedString(@"deviceinfotimeout", "deviceinfotimeout")];
            [__weakSelf.tableView footerEndRefreshing];
        }
        if (devInfo)
        {
            [__weakSelf.array addObject:devInfo];
            nForCount ++;
            __weakSelf.nCount++;
        }
        if (nCount==nForCount)
        {
            [__weakSelf.tableView reloadData];
            [__weakSelf.tableView footerEndRefreshing];
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_HOME_TABLEVIEW_VC object:__weakSelf.array];
        }
    };
    [_devService requestDeviceLimit:nIndex count:kRequestDeviceNumber];
    DLog(@"array:%@",_array);
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
            [__weakSelf.view makeToast:NSLocalizedString(@"deviceinfotimeout", "deviceinfotimeout")];
            [__weakSelf.tableView headerEndRefreshing];
            NSLog(@"获取设备信息超时");
            [[NSNotificationCenter defaultCenter] postNotificationName:NS_GET_DEVICE_LIST_VC object:nil];
            if (__weakSelf.nTimeOut <=2) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^{[__weakSelf initData:0];});
            }
            __weakSelf.nTimeOut ++;
            return ;
        }
        if (devInfo) {
            [aryList addObject:devInfo];
            nForCount ++;
            __weakSelf.nCount++;
        }
        if (nCount==nForCount) {
            [__weakSelf.array removeAllObjects];
            [__weakSelf.array addObjectsFromArray:aryList];
            [aryList removeAllObjects];
            aryList = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:NSUPDATE_HOME_TABLEVIEW_VC object:__weakSelf.array];
                [__weakSelf.tableView reloadData];
                [__weakSelf.tableView headerEndRefreshing];
            });
            __weakSelf.nTimeOut = 0;
        }
    };
    [_devService requestDeviceLimit:nIndex count:kRequestDeviceNumber];
}

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
    AddDevViewController *addDev = [[AddDevViewController alloc] init];
    [self.parentViewController presentViewController:addDev animated:YES completion:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _devService = nil;
    _tableView = nil;
    _array = nil;
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

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
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
    NSString *strImage = devModel.iDevOnline ? @"deviceOn" : @"deviceOff";
    [cell.imgView setImage:[UIImage imageNamed:strImage]];
    [cell.lblDevNO setText:devModel.strDevName];
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
 //   [self.view.window.rootViewController presentViewController:devInfoView animated:YES completion:nil];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableviewCellHeight;
}


@end
