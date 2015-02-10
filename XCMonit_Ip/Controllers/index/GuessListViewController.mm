//
//  GuessListViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/11/18.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "GuessListViewController.h"
#import "Toast+UIView.h"
#import "CustomNaviBarView.h"
#import "DeviceInfoDb.h"
#import "XCNotification.h"
#import "DevModel.h"
#import "DeviceCell.h"
#import "utilsMacro.h"
#import "DeviceService.h"
#import "ProgressHUD.h"
#import "DeviceInfoModel.h"
#import "MJRefresh.h"
#import "DecodeJson.h"
#import "RecordDb.h"
#import "PlayP2PViewController.h"
#import "PlayFourViewController.h"
#import "P2PInitService.h"


#define GUESS_DEVICE_IDENTIFIER @"GUESS_DEVICE_IDENTIFIER"


@interface GuessListViewController ()<UITableViewDelegate,UITableViewDataSource,DeviceDelegate>
{
    NSUInteger _nFormat;
}
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,strong) DeviceService *devService;
@property (nonatomic,assign) NSInteger nCount;
@property (nonatomic,assign) NSInteger nTimeOut;
@end

@implementation GuessListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    _array = [NSMutableArray array];

    _nFormat = 1;
    _devService = [[DeviceService alloc] init];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth,
                                                               kScreenHeight+HEIGHT_MENU_VIEW(20, 0)-[CustomNaviBarView barSize].height)];
    [self initData];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [_tableView addHeaderWithTarget:self action:@selector(headerRereshing)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enter_background) name:NS_APPLITION_ENTER_BACK object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initData) name:NSUPDATE_DEVICE_LIST_VC object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHomeView:) name:NSUPDATE_HOME_TABLEVIEW_VC object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(get_list_timeout) name:NS_GET_DEVICE_LIST_VC object:nil];
    
//    [self.view setUserInteractionEnabled:YES];
    
    // Do any additional setup after loading the view.
}
-(void)enter_background
{
    [[P2PInitService sharedP2PInitService] setP2PSDKNull];
}
-(void)headerRereshing
{
    [self initData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)initUI
{
    [self setNaviBarTitle:XCLocalized(@"home")];    // 设置标题
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateHighlighted];
    [btn addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarLeftBtn:btn];
    [self setNaviBarRightBtn:nil];
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)initData
{
    __weak GuessListViewController *__weakSelf = self;
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
                dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^{[__weakSelf initData];});
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
                   [__weakSelf.tableView headerEndRefreshing];
               });
            
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [__weakSelf.view makeToast:XCLocalized(@"devDone")];
                [__weakSelf.tableView reloadData];
            });
            __weakSelf.nTimeOut = 0;
        }
    };
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [ProgressHUD show:@""];
//    });
    [_devService queryDeviceNumber];
}
-(void)formatConvert:(UIButton*)_btn
{
    if([_btn.titleLabel.text isEqualToString:@"P2P"])
    {
        _nFormat = 2;
        [_btn setTitle:@"TRAN" forState:UIControlStateNormal];
    }else
    {
        
        _nFormat = 1;
        [_btn setTitle:@"P2P" forState:UIControlStateNormal];
    }
}

#pragma mark TableVieww委托

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    DeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:GUESS_DEVICE_IDENTIFIER];
    if (cell==nil) {
        cell = [[DeviceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GUESS_DEVICE_IDENTIFIER];
    }
    
    DeviceInfoModel *devModel = [_array objectAtIndex:indexPath.row];
//    [cell setPlayModel];
    cell.nStatus = devModel.iDevOnline;
    [cell setDevName:@""];
    cell.lblDevNO.text = devModel.strDevName;
    NSString *strImage = devModel.iDevOnline ? @"deviceOn" : @"deviceOff";
    [cell.imgView setImage:[UIImage imageNamed:strImage]];
    cell.strName = devModel.strDevName;
    cell.strDevNO = devModel.strDevNO;
    cell.nType = [devModel.strDevType integerValue];
    cell.lblType.text = [DecodeJson getDeviceTypeByType:[devModel.strDevType intValue]];
    //图片暂时使用默认的
    cell.delegate = self;
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeviceInfoModel *devModel = [_array objectAtIndex:indexPath.row];
    if ([devModel.strDevType integerValue]<2000)
    {
        //单通道播放视频
        PlayP2PViewController *playController = [[PlayP2PViewController alloc] initWithNO:devModel.strDevNO name:devModel.strDevName format:_nFormat];
        [self presentViewController:playController animated:YES completion:nil];
    }
    else
    {
        //多屏幕播放视频
        PlayFourViewController *playController = [[PlayFourViewController alloc] initWithDevInfo:devModel];
        [self presentViewController:playController animated:YES completion:nil];
    }
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableviewDeviceCellHeight;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)recordVideo:(NSString *)strNO name:(NSString *)strDevName line:(int)nLine
{
    NSArray *aryRecord = [RecordDb queryRecord:strNO];
    if (aryRecord.count<1)
    {
        [self.view makeToast:XCLocalized(@"noRecords")];
        return;
    }
    
}
-(void)playVideo:(NSString*)strNO name:(NSString*)strDevName type:(NSInteger)nType
{
#if 1
    DeviceInfoModel *devModel = nil;
    for (DeviceInfoModel *devInfoModel in _array)
    {
        if([devInfoModel.strDevNO isEqualToString:strNO])
        {
            devModel = devInfoModel;
            break;
        }
    }
    if (nType<2000)
    {
        //单通道播放视频
        PlayP2PViewController *playController = [[PlayP2PViewController alloc] initWithNO:strNO name:strDevName format:_nFormat];
        [self presentViewController:playController animated:YES completion:nil];
    }
    else
    {
        //多屏幕播放视频
        PlayFourViewController *playController = [[PlayFourViewController alloc] initWithDevInfo:devModel];
        [self presentViewController:playController animated:YES completion:nil];
        
    }
#endif
#if 0
    PlayFourViewController *playController = [[PlayFourViewController alloc] initWithNo:strNO];
    [self.parentViewController presentViewController:playController animated:YES completion:nil];
#endif
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


#pragma mark 排序
-(void)arrayInfo
{
    NSArray *array = [_array sortedArrayUsingComparator:guessCmp];
    [_array removeAllObjects];
    [_array addObjectsFromArray:array];
}

NSComparator guessCmp = ^(id obj1, id obj2)
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



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
