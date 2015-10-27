//
//  RTSPListViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RTSPListViewController.h"
#import "CustomNaviBarView.h"
#import "DIrectDVR.h"


#import "RTSPAddDeviceViewController.h"
#import "RtspInfo.h"
#import "RtspInfoDb.h"
#import "UtilsMacro.h"
#import "RecordDb.h"
#import "RtspCell.h"
#import "Toast+UIView.h"
#import "RTSPPlayViewController.h"
#import "SubRTSPView.h"
#import "RtspRecordViewController.h"
#import "UIView+convenience.h"
#import "XCDirect_InfoView.h"
#import "UIScrollView+MJRefresh.h"

@interface RTSPListViewController ()<UITableViewDelegate,UITableViewDataSource,UIFolderTableViewDelegate,SubRTSPDelegate,RtspCellDelegate,XCDirectDelegate,UIScrollViewDelegate>
{
    SubRTSPView *subVc;
    NSIndexPath *oldPath;
    XCDirect_InfoView *directView;
}
@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,strong) UIButton *btnDel;
@property (nonatomic,strong) NSMutableDictionary *tableDic;

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

#pragma mark navBar 加入  添加与删除按钮
- (void)initUI
{
    [self setNaviBarTitle:XCLocalized(@"rtspList")];
    
    UIButton *btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnBack setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [btnBack setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    [self setNaviBarLeftBtn:btnBack];
    [btnBack addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *downView = [[UIView alloc] initWithFrame:Rect(0, kScreenSourchHeight-49, kScreenSourchWidth, 49)];
    [self.view addSubview:downView];
    
    UILabel *sLine3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 0.5)];
    sLine3.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    sLine3.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [downView addSubview:sLine3];
    
    UILabel *lblTemp = [[UILabel alloc] initWithFrame:Rect(kScreenSourchWidth/2-0.25, 0, 0.5, 49)];
    [lblTemp setBackgroundColor:[UIColor colorWithRed:198/255.0
                                                green:198/255.0
                                                 blue:198/255.0
                                                alpha:1.0]];
    [downView addSubview:lblTemp];
    
    UIButton *btnAdd = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnAdd setImage:[UIImage imageNamed:@"add_icon"] forState:UIControlStateNormal];
    [btnAdd addTarget:self action:@selector(addDevice) forControlEvents:UIControlEventTouchUpInside];
    [downView addSubview:btnAdd];
    btnAdd.frame = Rect(0, 1, kScreenSourchWidth/2-1,48);
    
    
    
    _btnDel = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnDel setImage:[UIImage imageNamed:@"dustbin_ico"] forState:UIControlStateNormal];
    [_btnDel setImage:[UIImage imageNamed:@"ok_ico"] forState:UIControlStateSelected];
    [_btnDel addTarget:self action:@selector(delDevice) forControlEvents:UIControlEventTouchUpInside];
    [downView addSubview:_btnDel];
    _btnDel.frame = Rect(kScreenSourchWidth/2, 1, kScreenSourchWidth/2-1, 48);
    
    
}
#pragma mark 进入添加设备界面
-(void)addDevice
{
    directView.hidden = YES;
    RTSPAddDeviceViewController *rtsp = [[RTSPAddDeviceViewController alloc] init];
    [self presentViewController:rtsp animated:YES completion:^{}];
}
#pragma mark 开始界面
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateUI];
}
#pragma mark 设置头信息
-(void)updateUI
{
    [_tableView reloadData];
    if (_array.count==0)
    {
        [[_tableView viewWithTag:1001] removeFromSuperview];
        [[_tableView viewWithTag:1002] removeFromSuperview];
        [[_tableView viewWithTag:1003] removeFromSuperview];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:Rect((kScreenWidth-110.5)/2, 132.5, 99, 70)];
        imgView.image=[UIImage imageNamed:@"no_device"];
        [_tableView addSubview:imgView];
        imgView.tag = 1001;
        
        UILabel *lblInfo = [[UILabel alloc] initWithFrame:Rect(0, imgView.frame.origin.y+imgView.frame.size.height+20.5, kScreenWidth, 39)];
        
        [lblInfo setText:XCLocalized(@"noDevice")];
        [lblInfo setTextAlignment:NSTextAlignmentCenter];
        [_tableView addSubview:lblInfo];
        [lblInfo setTextColor:RGB(208, 208, 208)];
        [lblInfo setFont:[UIFont fontWithName:@"Helvetica" size:14.0f]];
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

        [[_tableView viewWithTag:1002] removeFromSuperview];
        [[_tableView viewWithTag:1002] removeFromSuperview];
        [[_tableView viewWithTag:1003] removeFromSuperview];
    }
}
#pragma mark 删除设备
-(void)delDevice
{
    directView.hidden = YES;
    if(_btnDel.selected)
    {
        _btnDel.selected = NO;
        [_tableView setEditing:NO animated:YES];
        NSArray *array = [_tableDic allValues];
        for (RtspInfo *info in array)
        {
            [RtspInfoDb removeByIndex:info.nId];
        }
        __weak RTSPListViewController *rtspSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [rtspSelf initDataInfo];
            [rtspSelf updateUI];
            
        });
    }
    else
    {
        [_tableDic removeAllObjects];
        [_tableView setEditing:YES animated:YES];
        _btnDel.selected = YES;
    }
}
#pragma mark 退出
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initUI];

    _tableView = [[UIFolderTableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth,
                kScreenHeight+HEIGHT_MENU_VIEW(20, 0)-XC_TAB_BAR_HEIGHT-[CustomNaviBarView barSize].height)];
    [self.view addSubview:_tableView];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    

    _tableDic = [NSMutableDictionary dictionary];
    
    directView = [[XCDirect_InfoView alloc] initWithFrame:Rect(0, 0, 163, 39)];
    [self.view addSubview:directView];
    directView.hidden = YES;
    directView.delegate = self;
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    directView.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initDataInfo];
}

#pragma mark 加载rtsp信息
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
    __weak RTSPListViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.tableView reloadData];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}

#pragma mark 初始化每一行数据
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RtspCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rtspcell"];
    if (cell==nil)
    {
        cell = [[RtspCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"rtspcell"];
    }
    cell.delegate = self;
    RtspInfo *info = [_array objectAtIndex:indexPath.row];
    cell.lblDevName.text = info.strDevName;
    NSString *strText = [NSString stringWithFormat:@"%@:%li",info.strAddress,(long)info.nPort];
    cell.lblStatus.text = strText;
    cell.nIndex = indexPath.row;
    
    NSString *strDevice = info.strType;
    cell.nsIndexPath = indexPath;
    if ([strDevice isEqualToString:@"IPC"])
    {
        [cell.imgView setImage:[UIImage imageNamed:@"rtsp_drivers"]];
    }
    else
    {
        [cell.imgView setImage:[UIImage imageNamed:@"device_dvr"]];
    }
    return cell;
}
#pragma mark 选择事件
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    directView.hidden = YES;
    if (_btnDel.selected)
    {
        [_tableDic setObject:[_array objectAtIndex:indexPath.row] forKey:indexPath];
        return ;
    }
    
    RtspInfo *info = [_array objectAtIndex:indexPath.row];
    
    if ([info.strType isEqualToString:@"IPC"])
    {
        RTSPPlayViewController *rtspPlay = [[RTSPPlayViewController alloc] initWithContentRtsp:info channel:0];
        [self presentViewController:rtspPlay animated:YES completion:^{}];
        return;
    }
    NSInteger rows = (info.nChannel / 4) + ((info.nChannel % 4) > 0 ? 1 : 0);
    rows = rows>=4 ? 4 : rows;
    if(subVc)
    {
        subVc = nil;
    }
    subVc = [[SubRTSPView alloc] initWithFrame:Rect(0, 0, kScreenWidth, rows*70+19)];
    subVc.delegate = self;
    subVc.nCount = info.nChannel;
    self.tableView.scrollEnabled = NO;
    UIFolderTableView *folderTableView = (UIFolderTableView *)tableView;
    [folderTableView openFolderAtIndexPath:indexPath WithContentView:subVc
                                openBlock:^(UIView *subClassView, CFTimeInterval duration, CAMediaTimingFunction *timingFunction)
                                {
                                     // opening actions
                                 }
                                closeBlock:^(UIView *subClassView, CFTimeInterval duration, CAMediaTimingFunction *timingFunction)
                                {
                                    // closing actions
                                }
                                completionBlock:^{
                               self.tableView.scrollEnabled = YES;
                           }];
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableViewRTSPCellHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_btnDel.selected)
    {
        [_tableDic removeObjectForKey:indexPath];
        DLog(@"tableDic:%@",_tableDic);
    }
}


-(void)dealloc
{
    [_array removeAllObjects];
    _array = nil;
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

-(void)playRtspConnect:(NSInteger)nChannel
{
    __weak UIFolderTableView *_folderTableView = (UIFolderTableView *)_tableView;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [_folderTableView performClose];
    });
    NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
    if(indexPath)
    {
        DLog(@"indexPath.row:%ld",(long)indexPath.row);
        RtspInfo *info = [_array objectAtIndex:indexPath.row];
        oldPath = indexPath;
        RTSPPlayViewController *rtspPlay = [[RTSPPlayViewController alloc] initWithContentRtsp:info channel:nChannel-1];
        [self presentViewController:rtspPlay animated:YES completion:^{}];
    }else if (oldPath)
    {
        DLog(@"indexPath.row:%ld",(long)oldPath.row);
        RtspInfo *info = [_array objectAtIndex:oldPath.row];
        RTSPPlayViewController *rtspPlay = [[RTSPPlayViewController alloc] initWithContentRtsp:info channel:nChannel-1];
        [self presentViewController:rtspPlay animated:YES completion:^{}];
    }
}

-(void)recordVideoByIndex:(NSInteger)nIndex path:(NSIndexPath*)nsIndexPath
{
    directView.hidden = NO;

    CGRect rectInTableView = [_tableView rectForRowAtIndexPath:nsIndexPath];
    CGRect rectInSuperview = [_tableView convertRect:rectInTableView toView:[_tableView superview]];
    
    directView.nCount = nsIndexPath.row;
    [directView setFrame:Rect(self.view.frameWidth-210,kTableViewRTSPCellHeight/2-19+rectInSuperview.origin.y, 163, 39)];
}
#pragma mark XCDirect delegate  编辑
-(void)update_Direct:(NSInteger)nIndex
{
    directView.hidden = YES;
    RtspInfo *info = [_array objectAtIndex:nIndex];
    RTSPAddDeviceViewController *rtspAdd = [[RTSPAddDeviceViewController alloc] initWithRtsp:info];
    [self presentViewController:rtspAdd animated:YES completion:nil];
}
#pragma mark XCDirect delegate  查看录像
-(void)record_Direct:(NSInteger)nIndex
{
    directView.hidden=YES;
    RtspInfo *info = [_array objectAtIndex:nIndex];
    NSString *strPath;
    NSString *strAdmin;
    if ([info.strUser isEqualToString:@""])
    {
        strAdmin = @"";
    }
    else
    {
        strAdmin = [NSString stringWithFormat:@"%@:%@@",info.strUser,info.strPwd];
    }
    
    if ([info.strType isEqualToString:@"IPC"])
    {
        strPath = [NSString stringWithFormat:@"rtsp://%@%@:%lu",strAdmin,info.strAddress,(long)info.nPort];//主码流
    }
    else if([info.strType isEqualToString:@"DVR"])
    {
        /*
            修改
         */
//        testConnect([info.strUser UTF8String], [info.strPwd UTF8String],[info.strAddress UTF8String],info.nPort);
//        return;
        strPath = [NSString stringWithFormat:@"rtsp://%@%@:%lu",strAdmin,info.strAddress,(long)info.nPort];
    }
    else
    {
        strPath = [NSString stringWithFormat:@"rtsp://%@%@:%d",strAdmin,info.strAddress,(int)info.nPort];
    }
    DLog(@"链接地址:%@",strPath);
    
    NSArray *array = [RecordDb queryRtsp:strPath name:info.strDevName];
    if(array.count>0)
    {
        RtspRecordViewController *rtspRecord = [[RtspRecordViewController alloc] initWithPath:strPath name:info.strDevName];
        [self presentViewController:rtspRecord animated:YES completion:nil];
    }
    else
    {
        [self.view makeToast:XCLocalized(@"noRecords") duration:1.0f position:@"center"];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    directView.hidden = YES;
}
 
@end
