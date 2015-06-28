//
//  HomeViewController.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-20.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "HomeViewController.h"
#import "CustomNaviBarView.h"
#import "CloudViewController.h"
#import "PlayCloudViewController.h"
#import "DeviceInfoDb.h"
#import "XCNotification.h"
#import "DevModel.h"
#import "DeviceCell.h"
#import "utilsMacro.h"
#import "PlayP2PViewController.h"
#import "MJRefresh.h"
#import "DeviceInfoModel.h"
#import "RecordViewController.h"
#import "Toast+UIView.h"
#import "PlayFourViewController.h"
#import "IndexViewController.h"
#import "RecordDb.h"
#import "QrcodeViewController.h"
#import "DecodeJson.h"
#import "PlayForP2PViewController.h"
#define HOME_DEVICE_IDENTIFIER    @"deviceIdentifier"

@interface HomeViewController ()<UITableViewDelegate,UITableViewDataSource,DeviceDelegate>
{
    NSUInteger _nFormat;
}
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *array;


@end

@implementation HomeViewController

-(void)dealloc
{
    DLog(@"HomeViewController dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_tableView removeFromSuperview];
    [_array removeAllObjects];
    
    _array = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _array = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)loadView
{
    [super loadView];


}
- (void)initUI
{
    [self setNaviBarTitle:XCLocalized(@"home")];    // 设置标题
    [self setNaviBarLeftBtn:nil];       // 若不需要默认的返回按钮，直接赋nil
    [self setNaviBarRightBtn:nil];
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
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateUIData];
}
- (void)viewDidLoad
{
    _nFormat = 1;
    [super viewDidLoad];
    [self initUI];
    // Do any additional setup after loading the view.
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth,
                                kScreenHeight+HEIGHT_MENU_VIEW(20, 0)-XC_TAB_BAR_HEIGHT-[CustomNaviBarView barSize].height)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initData) name:NSUPDATE_DEVICE_LIST_VC object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHomeView:) name:NSUPDATE_HOME_TABLEVIEW_VC object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(get_list_timeout) name:NS_GET_DEVICE_LIST_VC object:nil];

    [self.view setUserInteractionEnabled:YES];
}
-(void)enter_ListView
{
    [[IndexViewController sharedIndexViewController] setIndexViewController:1];
}
-(void)get_list_timeout
{
    [self.view makeToast:XCLocalized(@"deviceinfotimeout")];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}
-(void)updateHomeView:(NSNotification*)notification
{
     NSArray *array = [notification object];
    [_array removeAllObjects];
    [_array addObjectsFromArray:array];
    [self updateUIData];
}

-(void)updateUIData
{
    [_tableView reloadData];
    if (_array.count==0)
    {
        [[_tableView viewWithTag:1001] removeFromSuperview];
        [[_tableView viewWithTag:1002] removeFromSuperview];
        [[_tableView viewWithTag:1003] removeFromSuperview];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:Rect((kScreenWidth - 97)/2, 132.5, 97, 70)];
        imgView.image=[UIImage imageNamed:@"no_device"];
        [_tableView addSubview:imgView];
        imgView.tag = 1001;
        
        UILabel *lblInfo = [[UILabel alloc] initWithFrame:Rect(0, imgView.frame.origin.y+imgView.frame.size.height+20.5, kScreenWidth, 39)];
        [lblInfo setText:XCLocalized(@"noDevice")];
        [lblInfo setTextAlignment:NSTextAlignmentCenter];
        [lblInfo setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
        [lblInfo setTextColor:RGB(208, 208, 208)];
        [_tableView addSubview:lblInfo];
        lblInfo.tag = 1002;
        
        UIButton *btn = [UIButton  buttonWithType:UIButtonTypeCustom];
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
//invite+udp://192.168.1.2:6000

//invite

-(void)addDevice
{
    QrcodeViewController *qrcode = [[QrcodeViewController alloc] init];
    [self presentViewController:qrcode animated:YES completion:^{}];
}

-(void)initData
{

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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

#pragma mark TableVieww委托

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    DeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:HOME_DEVICE_IDENTIFIER];
    if (cell==nil) {
        cell = [[DeviceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:HOME_DEVICE_IDENTIFIER];
    }  
    
    DeviceInfoModel *devModel = [_array objectAtIndex:indexPath.row];
    [cell setPlayModel];
    cell.nStatus = devModel.iDevOnline;
    [cell setDevName:@""];
    cell.lblDevNO.text = devModel.strDevName;
    NSString *strImage = devModel.iDevOnline ? @"deviceOn" : @"deviceOff";
    [cell.imgView setImage:[UIImage imageNamed:strImage]];
    cell.strName = devModel.strDevName;
    cell.strDevNO = devModel.strDevNO;
    cell.nType = [devModel.strDevType integerValue];
    cell.lblType.text = [DecodeJson getDeviceTypeByType:[devModel.strDevType intValue]]; //[[IndexViewController sharedIndexViewController] getDeviceTypeByType:[devModel.strDevType integerValue]];
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
        [self.parentViewController presentViewController:playController animated:YES completion:nil];
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

#pragma mark 修改
-(void)recordVideo:(NSString *)strNO name:(NSString *)strDevName line:(int)nLine
{
    DeviceInfoModel *devModel = nil;
    for (DeviceInfoModel *devInfoModel in _array)
    {
        if([devInfoModel.strDevNO isEqualToString:strNO])
        {
            devModel = devInfoModel;
            break;
        }
    }
    if ([devModel.strDevType intValue]<2000) {
        return ;
    }
    PlayCloudViewController *playCloud = [[PlayCloudViewController alloc] initWithDev:devModel];
    [self presentViewController:playCloud animated:YES completion:nil];
   
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
        [self.parentViewController presentViewController:playController animated:YES completion:nil];
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
