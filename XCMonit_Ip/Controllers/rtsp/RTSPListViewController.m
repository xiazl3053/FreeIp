//
//  RTSPListViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RTSPListViewController.h"
#import "CustomNaviBarView.h"
#import "RTSPAddDeviceViewController.h"
#import "RtspInfo.h"
#import "RtspInfoDb.h"
#import "UtilsMacro.h"
#import "RtspCell.h"
#import "RTSPPlayViewController.h"

@interface RTSPListViewController ()<UITableViewDelegate,UITableViewDataSource>

{
    
}
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *array;

@end

@implementation RTSPListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)initUI
{
    [self setNaviBarTitle:NSLocalizedString(@"rtspList", nil)];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    UIButton *btnAdd = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [btnAdd addTarget:self action:@selector(addDevice) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarRightBtn:btnAdd];
}
-(void)addDevice
{
    RTSPAddDeviceViewController *rtsp = [[RTSPAddDeviceViewController alloc] init];
    [self presentViewController:rtsp animated:YES completion:^{}];
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    // Do any additional setup after loading the view.
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth,
                                                               kScreenHeight+HEIGHT_MENU_VIEW(20, 0)-44-[CustomNaviBarView barSize].height)];
    
    
    
//    _array = [[NSMutableArray alloc] init];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initDataInfo];
}


-(void)initDataInfo
{
    if(_array)
    {
        [_array removeAllObjects];
        _array = nil;
    }
    NSMutableArray *aryList = [RtspInfoDb queryAllRtsp];
    _array = [[NSMutableArray alloc] initWithArray:aryList];
    aryList = nil;
    DLog(@"_array:%@",_array);
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

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RtspCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rtpscell"];
    if (cell==nil)
    {
        cell = [[RtspCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"rtpscell"];
    }
    RtspInfo *info = [_array objectAtIndex:indexPath.row];
    cell.lblDevName.text = info.strDevName;
    cell.lblStatus.text = @"尝试连接";
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RTSPPlayViewController *rtspPlay = [[RTSPPlayViewController alloc]initWithContentPath:@"rtsp://192.168.8.107:554/1"];
    [self presentViewController:rtspPlay animated:YES completion:^{}];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableViewRTSPCellHeight;
}
-(void)dealloc
{
    [_array removeAllObjects];
    _array = nil;
}
-(BOOL)shouldAutorotate
{
    return NO;
}
@end
