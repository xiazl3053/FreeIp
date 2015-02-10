//
//  HomeViewController.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-20.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "HomeViewController.h"
#import "CustomNaviBarView.h"
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

#define HOME_DEVICE_IDENTIFIER    @"deviceIdentifier"

@interface HomeViewController ()<UITableViewDelegate,UITableViewDataSource,DeviceDelegate>
{
    NSUInteger _nFormat;
    UISwipeGestureRecognizer *_switpeGesture;
}
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *array;


@end

@implementation HomeViewController

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
    [self setNaviBarTitle:NSLocalizedString(@"home", "home")];    // 设置标题
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
- (void)viewDidLoad
{
    _nFormat = 1;
    [super viewDidLoad];
    [self initUI];
    // Do any additional setup after loading the view.
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth,
                                kScreenHeight+HEIGHT_MENU_VIEW(20, 0)-44-[CustomNaviBarView barSize].height)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initData) name:NSUPDATE_DEVICE_LIST_VC object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHomeView:) name:NSUPDATE_HOME_TABLEVIEW_VC object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(get_list_timeout) name:NS_GET_DEVICE_LIST_VC object:nil];
//    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    _switpeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(enter_ListView)];
    [_switpeGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:_switpeGesture];
    [self.view setUserInteractionEnabled:YES];
}
-(void)enter_ListView
{
    [[IndexViewController sharedIndexViewController] setIndexViewController:1];
}
-(void)get_list_timeout
{
    [self.view makeToast:NSLocalizedString(@"deviceinfotimeout", "deviceinfotimeout")];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    DLog(@"array:%@",_array);
    if(_tableView)
    {
        [_tableView reloadData];
    }
}

-(void)initData
{
    DLog(@"array:%@",_array);
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

#pragma mark TableVieww委托

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
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
    cell.lblDevNO.text = devModel.strDevName;
    NSString *strImage = devModel.iDevOnline ? @"deviceOn" : @"deviceOff";
    [cell.imgView setImage:[UIImage imageNamed:strImage]];
    cell.strName = devModel.strDevName;
    cell.strDevNO = devModel.strDevNO;
    cell.nType = [devModel.strDevType integerValue];
    cell.nStatus = devModel.iDevOnline;
    //图片暂时使用默认的
    cell.delegate = self;
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeviceInfoModel *devModel = [_array objectAtIndex:indexPath.row];
    if ([devModel.strDevType intValue]<2000)
    {
        //单通道播放视频
        PlayP2PViewController *playController = [[PlayP2PViewController alloc] initWithNO:devModel.strDevNO name:devModel.strDevName format:_nFormat];
        [self.parentViewController presentViewController:playController animated:YES completion:nil];
    }
    else
    {
        //多屏幕播放视频
        PlayFourViewController *playController = [[PlayFourViewController alloc] initWithDevInfo:devModel];
        [self.parentViewController presentViewController:playController animated:YES completion:nil];
    }
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableviewCellHeight;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)recordVideo:(NSString *)strNO name:(NSString *)strDevName line:(int)nLine
{
    RecordViewController *record = [[RecordViewController alloc] initWithNo:strNO status:nLine];
    [self.parentViewController presentViewController:record animated:YES completion:nil];
}
-(void)playVideo:(NSString*)strNO name:(NSString*)strDevName type:(NSInteger)nType
{
//    PlayP2PViewController *playController = [[PlayP2PViewController alloc] initWithNO:strNO name:strDevName format:_nFormat];
//    [self.parentViewController presentViewController:playController animated:YES completion:nil];
    //设备类型为1-1000属于IPC ,
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
        [self.parentViewController presentViewController:playController animated:YES completion:nil];
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
