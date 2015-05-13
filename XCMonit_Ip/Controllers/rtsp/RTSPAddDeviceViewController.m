//
//  RTSPAddDeviceViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RTSPAddDeviceViewController.h"
#import "CustomNaviBarView.h"
#import "ProgressHUD.h"
#import "RtspWlanCell.h"
#import "XCNotification.h"
#import "IQKeyboardManager.h"
#import "XCNotification.h"
#import "Toast+UIView.h"
#import "UIView+Extension.h"
#import "RtspInfoDb.h"
#import "RtspInfo.h"
#import "discovery.h"

#import "devdiscovery.h"

@interface RTSPAddDeviceViewController ()<UITableViewDataSource,UITableViewDelegate,RTSPLanDelegate>
{
    NSArray *segmentedArray;
    NSArray *segmentedArray1;
    NSMutableArray *aryDevice;
    UIButton *btnSelect;
    UIView *downView;
    RtspInfo *_rtspInfo;
    UIButton *btnManua,*btnSearch;
    UIView *searchView;
    UIView *srcView;
    
}

@property (nonatomic,strong) UITextField *txtName;
@property (nonatomic,strong) UITextField *txtAddress;
@property (nonatomic,strong) UITextField *txtPort;
@property (nonatomic,strong) UITextField *txtUser;
@property (nonatomic,strong) UITextField *txtPwd;
@property (nonatomic,strong) UISegmentedControl *segType;
@property (nonatomic,strong) UISegmentedControl *segChannel;
@property (nonatomic,strong) UIButton *btnIPC;
@property (nonatomic,strong) UIButton *btnDVR;
@property (nonatomic,strong) UIButton *btnNVR;
@property (nonatomic,strong) UIImageView *imgTab;
@property (nonatomic,strong) UITableView *tableView;

@end

@implementation RTSPAddDeviceViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithRtsp:(RtspInfo*)rtspInfo
{
    self = [super init];
    _rtspInfo = rtspInfo;
    return self;
}

-(void)setRtspInfo:(RtspInfo *)rtspInfo
{
    _rtspInfo = rtspInfo;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    [self addType];
    [self initViewInfo];
    [self.view setBackgroundColor:RGB(236, 236, 236)];
    if(aryDevice==nil)
    {
        aryDevice = [NSMutableArray array];
    }
    if (_rtspInfo)
    {
        _txtAddress.text = _rtspInfo.strAddress;
        _txtName.text = _rtspInfo.strDevName;
        _txtPort.text = [NSString stringWithFormat:@"%d",(int)_rtspInfo.nPort];
        _txtUser.text = _rtspInfo.strUser;
        _txtPwd.text = _rtspInfo.strPwd;
        
        [self setNaviBarTitle:XCLocalized(@"updRtsp")];
        
        if ([_rtspInfo.strType isEqualToString:@"IPC"]) {
            _btnDVR.enabled = NO;
            _btnNVR.enabled = NO;
            _segChannel.hidden = YES;
        }
        else if([_rtspInfo.strType isEqualToString:@"DVR"])
        {
            _btnIPC.enabled = NO;
            _btnNVR.enabled = NO;
            _segChannel.hidden = NO ;
            [self clickDeviceType:_btnDVR];
        }
        else if([_rtspInfo.strType isEqualToString:@"NVR"])
        {
            _btnDVR.enabled = NO;
            _btnIPC.enabled = NO;
            _segChannel.hidden = NO ;
            [self clickDeviceType:_btnNVR];
        }
    }
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [IQKeyboardManager sharedManager].shouldShowTextFieldPlaceholder = YES;
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [IQKeyboardManager sharedManager].shouldShowTextFieldPlaceholder = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doneKeyBoard) name:NSKEY_BOARD_RETURN_VC object:nil];
    [[NSNotificationCenter  defaultCenter] postNotificationName:NS_SEARCH_DEVICE_FOR_WLAN_VC object:nil];
    [[NSNotificationCenter  defaultCenter] addObserver:self selector:@selector(updateSearchData:) name:NS_SEARCH_DEVICE_FOR_WLAN_VC object:nil];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)updateSearchData:(NSNotification*)notify
{
    NSMutableArray *aryTemp = notify.object;
    __weak RTSPAddDeviceViewController *__self = self;
    DLog(@"aryDevice:%@---count:%d",aryTemp,(int)aryTemp.count);
    if (aryTemp.count == 0 ) {
        dispatch_async(dispatch_get_main_queue(),
        ^{
            //提示没有搜索到设备
            [__self.view makeToast:@""];
        });
    }
    for (RtspInfo *rtsp in aryTemp)
    {
        [aryDevice addObject:rtsp];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [__self.view addSubview:__self.tableView];
        [__self.tableView reloadData];
    });
}

-(void)doneKeyBoard
{
    if([_txtPwd isFirstResponder])
    {
        [_txtPwd resignFirstResponder];
    }
    else if([_txtAddress isFirstResponder])
    {
        [_txtAddress resignFirstResponder];
    }
    else if([_txtName isFirstResponder])
    {
        [_txtName resignFirstResponder];
    }
    else if([_txtPort isFirstResponder])
    {
        [_txtPort resignFirstResponder];
    }
    else if([_txtUser isFirstResponder])
    {
        [_txtUser resignFirstResponder];
    }
}

-(void)clickDeviceType:(UIButton*)btnType
{
    int nTag = (int)btnType.tag;
    
    for(int nIndex = 0;nIndex<3;nIndex++)
    {
        if (nTag != nIndex+1001)
        {
            ((UIButton*)[srcView viewWithTag:nIndex+1001]).selected = NO;
        }
    }
    if (nTag==1002)
    {
        [_txtPort setPlaceholder:XCLocalized(@"dvrPort")];
    }
    else
    {
        [_txtPort setPlaceholder:XCLocalized(@"devPort")];
    }
    
    btnSelect = btnType;
    btnType.selected = YES;
    _imgTab.frame = Rect((btnType.tag-1001)*kScreenWidth/3.0,39, kScreenWidth/3.0, 3);
    [self segmentAction:nTag];
}

-(void)addType
{
    btnManua = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnManua setTitleColor:RGB(189, 189, 189) forState:UIControlStateNormal];
    [btnManua setTitleColor:RGB(15, 173, 225) forState:UIControlStateSelected];
    [btnManua setTitle:XCLocalized(@"Manually") forState:UIControlStateNormal];
    [btnManua setBackgroundColor:RGB(255, 255, 255)];
    
    btnSearch = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSearch setTitleColor:RGB(189, 189, 189) forState:UIControlStateNormal];
    [btnSearch setTitleColor:RGB(15, 173, 225) forState:UIControlStateSelected];
    [btnSearch setTitle:XCLocalized(@"search") forState:UIControlStateNormal];
    [btnSearch setBackgroundColor:RGB(255, 255, 255)];
    
    [self.view addSubview:btnSearch];
    [self.view addSubview:btnManua];
    
    btnSearch.frame = Rect(0, [CustomNaviBarView barSize].height, kScreenWidth/2, 44);
    btnManua.frame = Rect(kScreenWidth/2, [CustomNaviBarView barSize].height, kScreenWidth/2, 44);
    [btnManua addTarget:self action:@selector(setManua) forControlEvents:UIControlEventTouchUpInside];
    [btnSearch addTarget:self action:@selector(setSearchInfo) forControlEvents:UIControlEventTouchUpInside];
}

-(void)setManua
{
    btnManua.selected = YES;
    btnSearch.selected = NO;
    [searchView removeFromSuperview];
    [self.view addSubview:srcView];
}

-(void)setSearchInfo
{
    btnSearch.selected = YES;
    btnManua.selected = NO;
    [_tableView removeFromSuperview];
    [srcView removeFromSuperview];
    [self.view addSubview:searchView];
}

-(void)printSearchDev
{
    discovery();
    DD_SearchDev();
    [self.view makeToast:XCLocalized(@"searching") duration:1.0 position:@"center"];
    [aryDevice removeAllObjects];
}

-(void)initViewInfo
{
    
    srcView = [[UIView alloc] initWithFrame:Rect(0, 135, kScreenWidth, kScreenSourchHeight-135)];
    [self.view addSubview:srcView];
   
    searchView = [[UIView alloc] initWithFrame:Rect(0, 135, kScreenWidth, kScreenSourchHeight-135)];
    UIImageView *imgView =[[UIImageView alloc] initWithFrame:Rect(kScreenWidth/2-49, 87, 99, 69)];
    [imgView setImage:[UIImage imageNamed:@"WIFI"]];
    [searchView addSubview:imgView];
    UIButton *btnSearchAction = [UIButton buttonWithType:UIButtonTypeCustom];
    [searchView addSubview:btnSearchAction];
    [btnSearchAction setTitle:XCLocalized(@"search") forState:UIControlStateNormal];
    [btnSearchAction setTitleColor:RGB(255,255,255) forState:UIControlStateNormal];
    [btnSearchAction addTarget:self action:@selector(printSearchDev) forControlEvents:UIControlEventTouchUpInside];
    [btnSearchAction setFrame:Rect(50, imgView.height+imgView.y+80, kScreenWidth-100, 40)];
    [btnSearchAction setBackgroundImage:[UIImage imageNamed:@"btnBG"] forState:UIControlStateNormal];
    [btnSearchAction setBackgroundImage:[UIImage imageNamed:@"btnCl"] forState:UIControlStateHighlighted];
    
    UILabel *lblInfo = [[UILabel alloc] initWithFrame:Rect(10, imgView.y+imgView.height+20, kScreenWidth-20, 20)];
    [searchView addSubview:lblInfo];
    [lblInfo setText:XCLocalized(@"WIFIOK")];
    [lblInfo setTextAlignment:NSTextAlignmentCenter];
    [lblInfo setTextColor:RGB(165, 165, 165)];
    [lblInfo setFont:[UIFont fontWithName:@"Helvetica" size:14]];
    
    _tableView = [[UITableView alloc] initWithFrame:Rect(0, 135, kScreenWidth, kScreenSourchHeight-135)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellAccessoryNone;
    
    _btnIPC = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnDVR = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnNVR = [UIButton buttonWithType:UIButtonTypeCustom];
    [srcView addSubview:_btnIPC];
    [srcView addSubview:_btnDVR];
    [srcView addSubview:_btnNVR];
    [srcView setBackgroundColor:[UIColor whiteColor]];
    
    _btnIPC.tag = 1001;
    _btnDVR.tag = 1002;
    _btnNVR.tag = 1003;
    
    [_btnIPC addTarget:self action:@selector(clickDeviceType:) forControlEvents:UIControlEventTouchUpInside];
    [_btnDVR addTarget:self action:@selector(clickDeviceType:) forControlEvents:UIControlEventTouchUpInside];
    [_btnNVR addTarget:self action:@selector(clickDeviceType:) forControlEvents:UIControlEventTouchUpInside];
    
    [_btnIPC setBackgroundColor:[UIColor whiteColor]];
    [_btnDVR setBackgroundColor:[UIColor whiteColor]];
    [_btnNVR setBackgroundColor:[UIColor whiteColor]];
    
    [_btnIPC setTitleColor:RGB(180, 180, 180) forState:UIControlStateNormal];
    [_btnDVR setTitleColor:RGB(180, 180, 180) forState:UIControlStateNormal];
    [_btnNVR setTitleColor:RGB(180, 180, 180) forState:UIControlStateNormal];
    
    [_btnIPC setTitleColor:RGB(15, 173, 225) forState:UIControlStateSelected];
    [_btnDVR setTitleColor:RGB(15, 173, 225) forState:UIControlStateSelected];
    [_btnNVR setTitleColor:RGB(15, 173, 225) forState:UIControlStateSelected];
    
    _btnIPC.frame = Rect(0, 0, kScreenWidth/3.0, 42);
    _btnDVR.frame = Rect(kScreenWidth/3.0, 0, kScreenWidth/3.0, 42);
    _btnNVR.frame = Rect(2*kScreenWidth/3.0,0, kScreenWidth/3.0, 42);
    
    _imgTab = [[UIImageView alloc] initWithFrame:Rect(0,39, kScreenWidth/3.0, 3)];
    [srcView addSubview:_imgTab];
    [_imgTab setImage:[UIImage imageNamed:@"btnBG"]];
    
    
    [_btnIPC setTitle:@"IPC" forState:UIControlStateNormal];
    [_btnDVR setTitle:@"DVR" forState:UIControlStateNormal];
    [_btnNVR setTitle:@"NVR" forState:UIControlStateNormal];
    
    UIView *view = [[UIView alloc] initWithFrame:Rect(0, 42, kScreenWidth, 25)];
    [view setBackgroundColor:RGB(236, 236, 236)];
    [srcView addSubview:view];
    [self addViewLine:67 x:0];
    
    _txtName = [[UITextField alloc] initWithFrame:Rect(19, 69, kScreenWidth-19, 45)];
    
    [self addViewLine:114 x:19];
    
    _txtAddress = [[UITextField alloc] initWithFrame:Rect(19, _txtName.frame.origin.y+47, kScreenWidth-19, 45)];
    
    [self addViewLine:161 x:19];
    
    _txtPort = [[UITextField alloc] initWithFrame:Rect(19, _txtAddress.frame.origin.y+47, kScreenWidth-19, 45)];
    
    [self addViewLine:208 x:19];
    
    _txtUser = [[UITextField alloc] initWithFrame:Rect(19, _txtPort.frame.origin.y+47, kScreenWidth-19, 45)];
    
    [self addViewLine:255 x:19];
    
    _txtPwd = [[UITextField alloc] initWithFrame:Rect(19, _txtUser.frame.origin.y+47, kScreenWidth-19, 45)];
    
    [self addViewLine:302 x:0];
    
    [_txtName setPlaceholder:XCLocalized(@"devName")];
    [_txtAddress setPlaceholder:XCLocalized(@"devAddr")];
    [_txtPort setPlaceholder:XCLocalized(@"devPort")];
    [_txtUser setPlaceholder:XCLocalized(@"devUser")];
    [_txtPwd setPlaceholder:XCLocalized(@"devPwd")];
    
    [_txtName setBorderStyle:UITextBorderStyleNone];
    [_txtAddress setBorderStyle:UITextBorderStyleNone];
    [_txtPort setBorderStyle:UITextBorderStyleNone];
    [_txtUser setBorderStyle:UITextBorderStyleNone];
    [_txtPwd setBorderStyle:UITextBorderStyleNone];
    
    
    UIColor *color = [UIColor grayColor];
    _txtName.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"devName") attributes:@{NSForegroundColorAttributeName: color}];
    _txtAddress.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"devAddr") attributes:@{NSForegroundColorAttributeName: color}];
    _txtPort.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"devPort") attributes:@{NSForegroundColorAttributeName: color}];
    _txtUser.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"devUser") attributes:@{NSForegroundColorAttributeName: color}];
    _txtPwd.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"devPwd") attributes:@{NSForegroundColorAttributeName: color}];
    
    [_txtPort setKeyboardType:UIKeyboardTypePhonePad];
    
    [_txtName setText:@"Device1"];
    
    [_txtPwd setSecureTextEntry:YES];
    
    [_txtPort setBackgroundColor:[UIColor whiteColor]];
    [_txtName setBackgroundColor:[UIColor whiteColor]];
    [_txtAddress setBackgroundColor:[UIColor whiteColor]];
    [_txtPort setBackgroundColor:[UIColor whiteColor]];
    [_txtUser setBackgroundColor:[UIColor whiteColor]];
    [_txtPwd setBackgroundColor:[UIColor whiteColor]];
    
    [srcView addSubview:_txtName];
    [srcView addSubview:_txtAddress];
    [srcView addSubview:_txtPort];
    [srcView addSubview:_txtUser];
    [srcView addSubview:_txtPwd];
    
    
    segmentedArray1 = [[NSArray alloc]initWithObjects:@"4",@"8",@"16",@"24",@"32",nil];
    //初始化UISegmentedControl
    _segChannel = [[UISegmentedControl alloc]initWithItems:segmentedArray1];
    _segChannel.frame = CGRectMake(20.0,_txtPwd.y+_txtPwd.height+10, 280.0, 30.0);
    _segChannel.selectedSegmentIndex = 0;//设置默认选择项索引
    _segChannel.segmentedControlStyle = UISegmentedControlStyleBezeled;
    
    [_segChannel setEnabled:NO forSegmentAtIndex:4];
    [_segChannel setEnabled:NO forSegmentAtIndex:3];
    [_segChannel setEnabled:NO forSegmentAtIndex:2];
    [_segChannel setEnabled:NO forSegmentAtIndex:1];
    
    [srcView addSubview:_segChannel];
    btnSelect = _btnIPC;
    btnSelect.selected = YES;
    [self segmentAction:btnSelect.tag];
    //downView.frame = Rect(0, _txtPwd.frame.origin.y+_txtPwd.frame.size.height, kScreenWidth, kScreenHeight-(_txtPwd.frame.origin.y+_txtPwd.frame.size.height)+HEIGHT_MENU_VIEW(20, 0));

    downView = [[UIView alloc] initWithFrame:Rect(0, _txtPwd.frame.origin.y+_txtPwd.frame.size.height, kScreenWidth, kScreenHeight-(_txtPwd.frame.origin.y+_txtPwd.frame.size.height)+HEIGHT_MENU_VIEW(20, 0))];
    [downView setBackgroundColor:RGB(236, 236, 236)];
    [srcView addSubview:downView];
//    [srcView setBackgroundColor:RGB(236, 236, 236)];
}

-(void)addViewLine:(CGFloat)fHeight x:(CGFloat)nX
{
    UILabel *sLine3 = [[UILabel alloc] initWithFrame:CGRectMake(nX, fHeight+0.5, kScreenWidth, 0.5)];
    sLine3.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine4 = [[UILabel alloc] initWithFrame:CGRectMake(nX, fHeight+1, kScreenWidth, 0.5)] ;
    sLine4.backgroundColor = [UIColor whiteColor];
    [srcView addSubview:sLine3];
    [srcView addSubview:sLine4];
}

-(void)segmentAction:(NSInteger)nTag
{
    switch (nTag) {
        case 1001:
        {
            downView.frame = Rect(0, _txtPwd.frame.origin.y+_txtPwd.frame.size.height, kScreenWidth, kScreenHeight-(_txtPwd.frame.origin.y+_txtPwd.frame.size.height)+HEIGHT_MENU_VIEW(20, 0));
            _segChannel.hidden = YES;
            _segChannel.selectedSegmentIndex = 0;
        }
        break;
        default:
        {
            _segChannel.hidden = NO;
            downView.frame = Rect(0, _txtPwd.y+_txtPwd.height+50, kScreenWidth, kScreenHeight-(_txtPwd.y+_txtPwd.height+50)+HEIGHT_MENU_VIEW(20, 0));
            [_segChannel setEnabled:YES forSegmentAtIndex:4];
            [_segChannel setEnabled:YES forSegmentAtIndex:3];
            [_segChannel setEnabled:YES forSegmentAtIndex:2];
            [_segChannel setEnabled:YES forSegmentAtIndex:1];
            _segChannel.selectedSegmentIndex = 0;
        }
        break;
    }
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)initUI
{
    [self setNaviBarTitle:XCLocalized(@"addrtsp")];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    UIButton *right = [CustomNaviBarView createNormalNaviBarBtnByTitle:XCLocalized(@"save") target:self action:@selector(updateDevName)];
    [self setNaviBarRightBtn:right];
}

-(void)updateDevName
{
    NSString *strName = _txtName.text;
    if ([strName isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"devNameNULL")];
        return ;
    }
    
    NSString *strAddress = _txtAddress.text;
    if ([strAddress isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"devAddrNULL")];
        return ;
    }
    
    NSString *strPort = _txtPort.text;
    if ([strPort isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"devPortNULL")];
        return ;
    }
    NSString *strChannel = [segmentedArray1  objectAtIndex:_segChannel.selectedSegmentIndex];
    if(_rtspInfo)
    {
        _rtspInfo.strAddress = _txtAddress.text;
        _rtspInfo.strDevName = _txtName.text;
        _rtspInfo.strUser = _txtUser.text;
        _rtspInfo.strPwd = _txtPwd.text;
        _rtspInfo.nPort = [strPort integerValue];
        _rtspInfo.nChannel = [strChannel integerValue];
        if([RtspInfoDb updateRtsp:_rtspInfo])
        {
            __weak RTSPAddDeviceViewController *__self = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [__self.view makeToast:XCLocalized(@"devUpdOK") ];
                
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [__self dismissViewControllerAnimated:YES completion:nil];
            });
        }
        else
        {
            [self.view makeToast:@"error"];
        }
    }
    else
    {
        RtspInfo *rtsp = [[RtspInfo alloc] init];
        rtsp.strAddress = _txtAddress.text;
        rtsp.strDevName = _txtName.text;
        rtsp.strUser = _txtUser.text;
        rtsp.strPwd = _txtPwd.text;
        rtsp.nPort = [strPort integerValue];
        rtsp.strType = btnSelect.titleLabel.text;
        rtsp.nChannel = [strChannel integerValue];
        BOOL bReturn = [RtspInfoDb addRtsp:rtsp];
        if (bReturn)
        {
            [self.view makeToast:XCLocalized(@"devAddOk")];
            [self dismissViewControllerAnimated:YES completion:
             ^{
                 
             }];
        }
        else
        {
            [self.view makeToast:@"error"];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

-(BOOL)shouldAutorotate
{
    return NO;
}
- (NSUInteger)supportedInterfaceOrientations NS_AVAILABLE_IOS(6_0)
{
    return UIInterfaceOrientationMaskPortrait;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return aryDevice.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strRtspWlan = @"RTSP_WLAN_IDENTIFIER";
    RtspWlanCell *cell = [tableView dequeueReusableCellWithIdentifier:strRtspWlan];
    if(cell==nil)
    {
        cell = [[RtspWlanCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strRtspWlan];
    }
    [cell setDevInfo:[aryDevice objectAtIndex:indexPath.row]];
    UIView *view = [[UIView alloc] initWithFrame:cell.bounds];
    view.backgroundColor = [UIColor clearColor];
    [cell setSelectedBackgroundView:view];
    cell.delegate = self;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 91;
}

-(void)addDeviceInfo:(RtspInfo *)rtsp
{
    [RtspInfoDb addRtsp:rtsp];
    
    [aryDevice removeObject:rtsp];
    __weak RTSPAddDeviceViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [__self.tableView reloadData];
    });
    
}

@end
