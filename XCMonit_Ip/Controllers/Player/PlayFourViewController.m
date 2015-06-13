//
//  PlayFourViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/17.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//
#import "VideoView.h"
#import "PlayFourViewController.h"
#import "XCDecoderNew.h"
#import "XCNotification.h"
#import "DevInfoMacro.h"
#import "ProgressHUD.h"

#import "KxMovieGLView.h"
#import "Toast+UIView.h"
#import "CaptureService.h"
#import "CustomNaviBarView.h"
#import "DeviceInfoModel.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "Picture.h"
#import "UserInfo.h"
#import "PhoneDb.h"
#import "PTZView.h"
#import "UIView+Extension.h"
#define kVideoFrame  (kScreenWidth/2 - 1)


@interface PlayControlModel : NSObject
@property (nonatomic,strong) XCDecoderNew *decode;
@property (nonatomic,strong) NSMutableArray *videoFrame;
@property (nonatomic,strong) UIImageView *glView;
@property (nonatomic,assign) NSInteger nPlayIndex;
@property (nonatomic,assign) BOOL bDecoding;

@end

@implementation PlayControlModel
@end

@interface PlayControllerView : NSObject
@property (nonatomic,assign ) CGRect mainRect;
@property (nonatomic,strong ) VideoView *mainView;
@property (nonatomic,assign ) BOOL bPlay;
@property (nonatomic,assign ) int nIndex;
@property (nonatomic,assign ) int nCurSel;
@property (nonatomic,copy   ) NSString *strKey;
@property (nonatomic,strong ) DeviceInfoModel *devModel;
@property (nonatomic,assign ) BOOL bRecord;


@end

@implementation PlayControllerView
@end

@interface PlayFourViewController ()<VideoViewDelegate,UIScrollViewDelegate,PTZViewDelegate>
{
    UIView    *_topHUD;
    UIView    *_downHUD;
    CGRect lastRect;
    BOOL bFull ;
    int nIndex;
    UITapGestureRecognizer *tapGesture;
    UITapGestureRecognizer *doubleGesture;
    int nOldIndex;
    UILabel   *_lblName;
    UIButton  *_doneButton;
    UIButton  *_recordBtn;
    VideoView *_currentView;
    UISwipeGestureRecognizer *rightRecogn;
    UISwipeGestureRecognizer *leftRegcogn;
    //UIView nIndex bPlay
    BOOL bScreen;
    dispatch_queue_t _dispatchQueue;
    UIPanGestureRecognizer *_panGesture;
    UIPinchGestureRecognizer *_pinchGester;
    CGFloat lastX,lastY;
    CGFloat fWidth,fHeight;
    UIImageView *bgTopImg;
    UIImageView *bgDownImg;
    BOOL bExit;
    int nArray[32];
    BOOL bNewStatus;//切换状态
    UIButton *btnHD,*btnBD;
}

@property (nonatomic,strong) PTZView *view_Ptz;
@property (nonatomic,strong) UIButton *btnPtz;
@property (nonatomic,strong) UIPageControl *pageControl;
@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,strong) UILabel  *borderLabel;
@property (nonatomic,strong) UIScrollView *scroll;
@property (nonatomic,strong) NSMutableDictionary *decoderInfo;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) NSString *strNO;
@property (nonatomic,assign) BOOL bPlay;
@property (nonatomic,strong) DeviceInfoModel *devModel;
@property (nonatomic,assign) int nDevChannel;
@property (nonatomic,strong) UIView *switchView;
@end

@implementation PlayFourViewController

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}
-(id)initWithDevInfo:(DeviceInfoModel*)devModel
{
    self = [super init];
    _devModel = devModel;
    _strNO = _devModel.strDevNO;
    int nType = [_devModel.strDevType intValue];
    if ((nType>2000 && nType <2100) || (nType>4000 && nType < 4100))
    {
        DLog(@"4通道dvr或者nvr");
        _nDevChannel = 4;
    }
    else if((nType>2100 && nType <2200) || (nType>4100 && nType < 4200))
    {
        DLog(@"8通道dvr或者nvr");
        _nDevChannel = 8;
    }
    else if((nType>2200 && nType <2300) || (nType>4200 && nType < 4300))
    {
        DLog(@"16通道dvr或者nvr");
        _nDevChannel = 16;
    }
    else if((nType>2300 && nType <2400) || (nType>4300 && nType < 4400))
    {
        DLog(@"24通道dvr或者nvr");
        _nDevChannel = 24;
    }
    else if((nType>2400 && nType <2500) || (nType>4400 && nType < 4500))
    {
        DLog(@"32通道dvr或者nvr");
        _nDevChannel = 32;
    }
    
    return  self;
}

#pragma mark P2P SDK检测到设备中断触发
-(void)P2PSDKDisConnect:(NSNotification*)notify
{
    NSString *strKey = (NSString*)[notify object];
    PlayControlModel *playModel = [_decoderInfo valueForKey:strKey];
    PlayControllerView *playView = [_array objectAtIndex:playModel.nPlayIndex];
    __weak PlayControllerView *__playView = playView;
    int nChannel = [strKey intValue];
    int nPlayIndex = (int)playModel.nPlayIndex;
    //如果有正在录像的  需要停止
    __weak PlayFourViewController *__weakSelf = self;
    __block NSString *__strKey = strKey;
    NSString *strInfo = XCLocalized(@"Disconnect");
    __block NSString *_strInfo = strInfo;

    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group,dispatch_get_global_queue(0, 0),
    ^{
        [__weakSelf closePlayForKey:__strKey];
    });
    dispatch_group_async(group,dispatch_get_main_queue(),
    ^{
       DLog(@"输出错误:%@",_strInfo);
       [__playView.mainView makeToast:_strInfo];
       [__weakSelf updateClickView];
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    nArray[nChannel]++;
    DLog(@"第%d个通道",nChannel);
    if (nArray[nChannel]<=3 && !bExit)
    {
        DLog(@"第%d次重连",nArray[nChannel]);
        dispatch_group_async(group,dispatch_get_main_queue(),
        ^{
            [__weakSelf startNewWindow:nPlayIndex channel:strKey];
        });
    }
    
}

#pragma mark 连接设备失败触发，包含ffmpeg与p2p连接设备两种动作
-(void)connectP2PFail:(NSNotification*)notify
{
    XCDecoderNew *decoder = [notify object];
    __weak XCDecoderNew *weakDecode = decoder;
    NSString *strKey = [NSString stringWithFormat:@"%d",decoder.nChannel];
    PlayControlModel *playModel = [_decoderInfo valueForKey:strKey];
    PlayControllerView *playView = [_array objectAtIndex:playModel.nPlayIndex];
    __weak PlayControllerView *__playView = playView;
    int nChannel = [strKey intValue];
    int nPlayIndex = (int)playModel.nPlayIndex;
    //如果有正在录像的  需要停止
    __weak PlayFourViewController *__weakSelf = self;
    __block NSString *__strKey = strKey;
    NSString *strInfo = [weakDecode.strError copy];
    __block NSString *_strInfo = strInfo;
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group,dispatch_get_global_queue(0, 0), ^{
        [__weakSelf closePlayForKey:__strKey];
    });
    dispatch_group_async(group,dispatch_get_main_queue(),
    ^{
         DLog(@"输出错误:%@",_strInfo);
         [__playView.mainView makeToast:_strInfo];
         [__weakSelf updateClickView];
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    nArray[nChannel]++;
    DLog(@"第%d个通道",nChannel);
    if (nArray[nChannel]<=3 && !bExit)
    {
        DLog(@"第%d次重连",nArray[nChannel]);
        
        dispatch_group_async(group,dispatch_get_main_queue(),
        ^{
             [__weakSelf startNewWindow:nPlayIndex channel:strKey];
        });
    }
}

#pragma mark 后台推送
-(void)backModel
{
    //释放SDK
    __weak PlayFourViewController *weakSelf = self;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        [weakSelf stopVideo];
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    DLog(@"GG");
    
    group = nil;
}

#pragma mark 加载推送
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectP2PFail:) name:NSCONNECT_P2P_DVR_FAIL_VC object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(P2PSDKDisConnect:) name:NSCONNECT_P2P_DISCONNECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backModel) name:NS_APPLITION_ENTER_BACK object:nil];
}
#pragma mark 关闭推送
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initToolBar];
    _decoderInfo = [NSMutableDictionary dictionary];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    _borderLabel = [[UILabel alloc] initWithFrame:Rect(0, 0, 0, 0)];
    [_borderLabel setBackgroundColor:[UIColor clearColor]];
    _borderLabel.layer.borderWidth = 1;
    _borderLabel.layer.borderColor = [[UIColor greenColor] CGColor];
    [self.view addSubview:_borderLabel];
    [_borderLabel setFrame:((PlayControllerView*)[_array objectAtIndex:0]).mainRect];
    bExit = NO;
    _dispatchQueue = dispatch_queue_create("decoder", DISPATCH_QUEUE_SERIAL);
    btnBD = [UIButton buttonWithType:UIButtonTypeCustom];
    btnHD = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnBD setImage:[UIImage imageNamed:@"full_bd"] forState:UIControlStateNormal];
    [btnHD setImage:[UIImage imageNamed:@"full_hd"] forState:UIControlStateNormal];
    [btnHD addTarget:self action:@selector(switchVideoInfo:) forControlEvents:UIControlEventTouchUpInside];
    [btnBD addTarget:self action:@selector(switchVideoInfo:) forControlEvents:UIControlEventTouchUpInside];
    btnBD.tag = 10088;
    btnHD.tag = 10089;
}

-(void)switchVideoInfo:(UIButton *)sender
{
    [btnBD setEnabled:NO];
    [btnHD setEnabled:NO];
    if (sender.tag==10089)
    {
        //切换成高清
        [self switchVideoCode:1];
    }
    else
    {
        //切换成标清
        [self switchVideoCode:2];
    }
}

-(void)switchVideoCode:(int)nCodeType
{
    PlayControllerView *playView = _array[nIndex];
    PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
    if (!playModel || !playModel.decode)
    {
        return ;
    }
    [self stopRecord:nIndex];
    playModel.decode.playing = NO;
    playModel.bDecoding = YES;
    //停止视频
    __weak PlayControllerView *__playView = playView;
    __weak PlayFourViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [ProgressHUD showPlayRight:XCLocalized(@"videoSwitch") viewInfo:__self.view];
    });
    
    if([playModel.decode getRealType]==1)
    {
         //使用sdk切换
        __weak XCDecoderNew *__decoder = playModel.decode;
        __weak NSString *__strKey = playView.strKey;
        __weak PlayFourViewController *__self = self;
        __block int __nCode = nCodeType;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0),
        ^{
                BOOL bFlag = [__decoder switchP2PCode:__nCode];
                dispatch_async(dispatch_get_main_queue(), ^{
                        [ProgressHUD dismiss];
                });
               if(bFlag)
               {
                   [__self playMovieWithChannel:__strKey];
               }
        });
    }
    else
    {
        __weak PlayFourViewController *__self = self;
        dispatch_group_t group = dispatch_group_create();
        int nChannel = [playView.strKey intValue];
        DLog(@"nChannel:%d",nChannel);
        dispatch_group_async(group, dispatch_get_global_queue(0, 0),
        ^{
             [__self closePlayForKey:__playView.strKey];
        });
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        __block int __nChannel = nChannel;
        __block int __nCodeType = nCodeType;
        DLog(@"码流类型:%d",nCodeType);
        dispatch_async(dispatch_get_main_queue(), ^{
            [ProgressHUD dismiss];
        });
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            [__self startPlayWithNO:__self.strNO channel:[NSString stringWithFormat:@"%d",__nChannel] codeType:__nCodeType];
        });
        
    }
}

#pragma mark view显示
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    PlayControlModel *playModel = [[PlayControlModel alloc] init];
    
    playModel.nPlayIndex = 0;
    ((PlayControllerView*)[_array objectAtIndex:nIndex]).bPlay = YES;
    ((PlayControllerView*)[_array objectAtIndex:nIndex]).strKey = @"0";
    [_decoderInfo setValue:playModel forKey:@"0"];
    
    __weak PlayFourViewController *weakSelf = self;
    
    __weak NSString *__strNO = _strNO;
    
    PlayControllerView *playView = (PlayControllerView *)[_array objectAtIndex:0];
    __weak PlayControllerView *__playView = playView;
    dispatch_async(dispatch_get_main_queue(),
    ^{
         [__playView.mainView makeToastActivity];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0),
   ^{
       [weakSelf startPlayWithNO:__strNO channel:@"0" codeType:2];
   });
}

#pragma mark 界面设置
-(void)initToolBar
{
    
    [self.view setBackgroundColor:RGB(250, 250, 250)];
    
    [self initTopView];
    
    [self initVideoView];
    
    [self initScrollView];
    
    [self initButtomView];
    
    [self.view setUserInteractionEnabled:YES];
    
    rightRecogn = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [rightRecogn setDirection:UISwipeGestureRecognizerDirectionRight];
    
    
    leftRegcogn = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [leftRegcogn setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    _pinchGester = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchEvent:)];
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
}


#pragma mark 顶部导航栏初始化
-(void)initTopView
{
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenWidth,50)];
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topHUD];
    
    _topHUD.alpha = 1;
    
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 49.6, kScreenWidth, 0.2)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 49.8, kScreenWidth, 0.2)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    [_topHUD addSubview:sLine1];
    [_topHUD addSubview:sLine2];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,15,kScreenWidth-60,20)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:_devModel.strDevName];
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [_lblName setTextColor:[UIColor blackColor]];
    [_topHUD addSubview:_lblName];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(5,3,44,44);
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    _doneButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch:)
          forControlEvents:UIControlEventTouchUpInside];
    [_topHUD addSubview:_doneButton];
    //横屏背景
    bgTopImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ptz_bg"]];
    bgDownImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ptz_bg"]];
    
    _btnPtz = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnPtz setImage:[UIImage imageNamed:@"ptz_control"] forState:UIControlStateNormal];
    
    
    _view_Ptz = [[PTZView alloc] initWithFrame:Rect(0, 0, 164, 114)];
    [self.view addSubview:_view_Ptz];
    _view_Ptz.hidden = YES;
    _view_Ptz.delegate = self;
    
    [_btnPtz addTarget:self action:@selector(showPtzView) forControlEvents:UIControlEventTouchUpInside];
}


#pragma mark 视频矿初始化
-(void)initVideoView
{
    
    VideoView *_mainView1 = [[VideoView alloc] initWithFrame:Rect(0,51, kVideoFrame, kVideoFrame)];
    
    VideoView *_mainView2 = [[VideoView alloc] initWithFrame:Rect(kVideoFrame+2,51, kVideoFrame, kVideoFrame)];
    
    VideoView *_mainView3 = [[VideoView alloc] initWithFrame:Rect(0,_mainView2.frame.origin.y+_mainView2.frame.size.height+1, kVideoFrame, kVideoFrame)];
    
    VideoView *_mainView4 = [[VideoView alloc] initWithFrame:Rect(kVideoFrame+2,_mainView3.frame.origin.y,kVideoFrame,kVideoFrame)];
    
    if (isPhone4)
    {
        _mainView1.frame = Rect(0,45, kVideoFrame, 120);
        _mainView2.frame = Rect(kVideoFrame+2,45, kVideoFrame, 120);
        _mainView3.frame = Rect(0,_mainView2.frame.origin.y+_mainView2.frame.size.height+1, kVideoFrame, 120);
        _mainView4.frame = Rect(kVideoFrame+2,_mainView3.frame.origin.y, kVideoFrame, 120);
    }
    
    [self.view insertSubview:_mainView1 atIndex:0];
    _mainView1.delegate = self;
    _mainView1.nCursel = 0;
    [self.view insertSubview:_mainView2 atIndex:0];
    _mainView2.nCursel = 1;
    _mainView2.delegate = self;
    
    [self.view insertSubview:_mainView3 atIndex:0];
    _mainView3.nCursel =2;
    _mainView3.delegate = self;
    [self.view insertSubview:_mainView4 atIndex:0];
    _mainView4.nCursel = 3;
    _mainView4.delegate = self;
    
    _mainView4.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _mainView1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _mainView3.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _mainView2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    PlayControllerView *play1 = [[PlayControllerView alloc] init];
    PlayControllerView *play2 = [[PlayControllerView alloc] init];
    PlayControllerView *play3 = [[PlayControllerView alloc] init];
    PlayControllerView *play4 = [[PlayControllerView alloc] init];
    
    play1.mainRect = _mainView1.frame;
    play2.mainRect = _mainView2.frame;
    play3.mainRect = _mainView3.frame;
    play4.mainRect = _mainView4.frame;
    
    play1.mainView = _mainView1;
    play2.mainView = _mainView2;
    play3.mainView = _mainView3;
    play4.mainView = _mainView4;
    
    _array = [NSMutableArray array];
    [_array addObject:play1];
    [_array addObject:play2];
    [_array addObject:play3];
    [_array addObject:play4];
}
#pragma mark 滚动条初始化
-(void)initScrollView
{
    VideoView *mainView = ((PlayControllerView *)[_array objectAtIndex:3]).mainView;
    CGFloat fTempHeight = mainView.frame.origin.y+mainView.frame.size.height;
    //滚动条
    _scroll = [[UIScrollView alloc] initWithFrame:Rect(0, fTempHeight+2, kScreenWidth, kScreenHeight-fTempHeight-70+HEIGHT_MENU_VIEW(20, 0))];
    [self.view addSubview:_scroll];
    nOldIndex = -1;
    CGFloat btnWidth = kScreenWidth / 4 ;
    CGFloat btnHeight = _scroll.frame.size.height / 2 ;
    int nWidth = 50;
    CGFloat btnOrgWidth=(btnWidth-nWidth)/2;
    CGFloat btnOrgHeight = (btnHeight-nWidth)/2;
    int nNumber,nRow;
    if(isPhone4)
    {
        //4个通道   4s以下s
        nNumber = _nDevChannel <= 4 ? 1 : _nDevChannel/4;
        nRow = _nDevChannel <= 4 ? _nDevChannel : 4;
        for (int i=0; i<nNumber;i++)
        {
            UIView *view = [[UIView alloc] initWithFrame:Rect(i*kScreenWidth, 36, kScreenWidth, _scroll.frame.size.height)];
            for (int j=0; j<nRow; j++)
            {
                UIView *sonView = [[UIView alloc] initWithFrame:Rect(j*btnWidth, 0, btnWidth, btnHeight)];
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                btn.frame = Rect((btnWidth-45)/2, (btnHeight-45)/2, 45, 45);
                NSString *strInfo = [NSString stringWithFormat:@"%d",i*4+j+1];
                [btn setTitle:strInfo forState:UIControlStateNormal];
                btn.tag = 1000 + j;
                
                [btn setBackgroundImage:[UIImage imageNamed:@"dvr_n"] forState:UIControlStateNormal];
                [btn setBackgroundImage:[UIImage imageNamed:@"dvr_h"] forState:UIControlStateHighlighted];
                
                [btn setTitleColor:RGB(102, 102, 102) forState:UIControlStateNormal];
                
                [btn addTarget:self action:@selector(connect_channelPlay:) forControlEvents:UIControlEventTouchUpInside];
                [sonView addSubview:btn];
                [view addSubview:sonView];
            }
            [_scroll addSubview:view];
        }
    }
    else
    {
        //8个通道 iphone5以上型号
        nNumber = _nDevChannel <= 8 ? 1 : _nDevChannel/8;
        nRow = _nDevChannel <= 8 ? _nDevChannel : 8;
        for (int i=0; i<nNumber;i++)
        {
            UIView *view = [[UIView alloc] initWithFrame:Rect(i*kScreenWidth, 6, kScreenWidth, _scroll.frame.size.height)];
            for (int j=0; j<nRow; j++)
            {
                
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                btn.frame = Rect(j%4*btnWidth+btnOrgWidth, (j%8)-4>=0 ? (btnHeight+btnOrgHeight) : btnOrgHeight, nWidth, nWidth);
                
                NSString *strInfo = [NSString stringWithFormat:@"%d",i*8+j+1];
                [btn setTitle:strInfo forState:UIControlStateNormal];
                btn.tag = 1000 + j;
                
                [btn setBackgroundImage:[UIImage imageNamed:@"dvr_n"] forState:UIControlStateNormal];
                
                [btn setBackgroundImage:[UIImage imageNamed:@"dvr_h"] forState:UIControlStateHighlighted];
                
                [btn setTitleColor:RGB(102, 102, 102) forState:UIControlStateNormal];
                
                [btn addTarget:self action:@selector(connect_channelPlay:) forControlEvents:UIControlEventTouchUpInside];
                
                [view addSubview:btn];
            }
            [_scroll addSubview:view];
        }
    }
    
    _scroll.delegate = self;
    _scroll.contentSize = CGSizeMake(kScreenWidth*nNumber,kScreenHeight-fHeight-70+HEIGHT_MENU_VIEW(20, 0));
    _scroll.pagingEnabled=YES;
    _scroll.scrollEnabled = NO;
    _scroll.showsHorizontalScrollIndicator = NO;
    [_scroll setScrollEnabled:YES];
    if(nNumber>1)
    {
        UIPageControl *pageControl = [[UIPageControl alloc] init];
        pageControl.center = CGPointMake(kScreenWidth * 0.5, kScreenHeight-39);
        pageControl.bounds = CGRectMake(0, 0, 150, 30);
        pageControl.numberOfPages = nNumber; // 一共显示多少个圆点（多少页）
        // 设置非选中页的圆点颜色
        pageControl.pageIndicatorTintColor = RGB(221, 221, 221);
        // 设置选中页的圆点颜色
        pageControl.currentPageIndicatorTintColor = RGB(15, 173, 225);
        // 禁止默认的点击功能
        pageControl.enabled = NO;
        [self.view addSubview:pageControl];
        _pageControl = pageControl;
    }
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    int page = _scroll.contentOffset.x / _scroll.frame.size.width;
    // 设置页码
    if(_pageControl)
    {
        _pageControl.currentPage = page;
    }
}

#pragma mark 底部工具栏
-(void)initButtomView
{
    _downHUD = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight-50,kScreenWidth, 50)];
    _downHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_downHUD];
    _downHUD.alpha = 1.0f;
    
    UILabel *sLine3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.1, kScreenWidth, 0.2)];
    sLine3.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.3, kScreenWidth, 0.2)] ;
    sLine4.backgroundColor = [UIColor whiteColor];
    sLine3.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine4.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    [_downHUD addSubview:sLine3];
    [_downHUD addSubview:sLine4];
    sLine3.tag = 10013;
    sLine4.tag = 10014;
    
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopBtn setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    [stopBtn setImage:[UIImage imageNamed:@"stop_h"] forState:UIControlStateHighlighted];
    [stopBtn addTarget:self action:@selector(stopCurVideo) forControlEvents:UIControlEventTouchUpInside];
    stopBtn.tag = 1002;
    stopBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UIButton *shotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [shotoBtn setImage:[UIImage imageNamed:@"shotopic"] forState:UIControlStateNormal];
    [shotoBtn setImage:[UIImage imageNamed:@"shotopic_h"] forState:UIControlStateHighlighted];
    [shotoBtn addTarget:self action:@selector(shotoPic) forControlEvents:UIControlEventTouchUpInside];
    
    shotoBtn.tag = 1003;
    _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_recordBtn setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    [_recordBtn addTarget:self action:@selector(recordVideo) forControlEvents:UIControlEventTouchUpInside];
    [_recordBtn setImage:[UIImage imageNamed:@"record_sel"] forState:UIControlStateSelected];
    [_recordBtn setImage:[UIImage imageNamed:@"record_select"] forState:UIControlStateHighlighted];
    _recordBtn.tag = 1004;
    
    
    [_downHUD addSubview:stopBtn];
    [_downHUD addSubview:shotoBtn];
    [_downHUD addSubview:_recordBtn];
    
    stopBtn.frame =  Rect(30, 1, 60, 49);
    [_recordBtn setFrame:Rect(90,1, 60, 49)];
    shotoBtn.frame =  Rect(150, 1, 60, 49);
    
    ((UIButton*)[_downHUD viewWithTag:1002]).enabled = NO;
    ((UIButton*)[_downHUD viewWithTag:1003]).enabled = NO;
    _recordBtn.enabled = NO;
    //    switchBtn.enabled = NO;
}


#pragma mark 横屏
-(void)setVerticalFrame
{
    if (bNewStatus) {
        return ;
    }
//    CGFloat width,height;
    fWidth = kScreenHeight;
    fHeight = kScreenWidth;
    
    _topHUD.frame = Rect(0, 0, fWidth,50);
    
    [_topHUD insertSubview:bgTopImg atIndex:0];
    [bgTopImg setFrame:_topHUD.bounds];
    
    [_lblName setTextColor:[UIColor whiteColor]];
    
    _lblName.frame = Rect(50, 15, fWidth- 160, 20);
    [_lblName setTextAlignment:NSTextAlignmentLeft];
    
    _currentView.frame = Rect(0, 0,fWidth, fHeight);
    
    _switchView.frame = Rect((fWidth - 240)/2+180, fHeight-(44+60), 60, 60);
    //    (width - 240)/2
    _downHUD.frame = Rect(0, fHeight-50, fWidth, 50);
    [_downHUD viewWithTag:1002].frame =  Rect(fWidth-180, 0, 60, 48);
    [_downHUD viewWithTag:1003].frame = Rect(fWidth-120,  0, 60, 48);
    [_downHUD viewWithTag:1004].frame =  Rect(fWidth-60, 0, 60, 48);
    
    btnHD.frame = Rect(fWidth-180,0, 60, 48);
    btnBD.frame = Rect(fWidth-120,0, 60, 48);
    [_topHUD addSubview:btnBD];
    [_topHUD addSubview:btnHD];
    
    [(UIButton*)[_downHUD viewWithTag:1002] setImage:[UIImage imageNamed:@"full_stop"] forState:UIControlStateNormal];
    [(UIButton*)[_downHUD viewWithTag:1002] setImage:[UIImage imageNamed:@"full_stop"] forState:UIControlStateHighlighted];
    [(UIButton*)[_downHUD viewWithTag:1003] setImage:[UIImage imageNamed:@"full_snap"] forState:UIControlStateNormal];
    [(UIButton*)[_downHUD viewWithTag:1004] setImage:[UIImage imageNamed:@"full_record"] forState:UIControlStateNormal];
    
    [_downHUD insertSubview:bgDownImg atIndex:0];
    [bgDownImg setFrame:_downHUD.bounds];
    
    [_btnPtz setFrame:Rect(fWidth-60, 0, 60, 49)];
    [_topHUD addSubview:_btnPtz];
    
    _view_Ptz.frame = Rect(fWidth-164, fHeight/2-57,164, 114);
    
    [_downHUD viewWithTag:10013].backgroundColor = RGB(198, 198, 198);;
    [_downHUD viewWithTag:10014].backgroundColor = [UIColor whiteColor];
    
    [_currentView addGestureRecognizer:leftRegcogn];
    [_currentView addGestureRecognizer:rightRecogn];
    [_currentView addGestureRecognizer:_pinchGester];
//    [_currentView addGestureRecognizer:_panGesture];
    bNewStatus = YES;
}

#pragma mark 竖屏
-(void)setHorizontalFrame
{
    bNewStatus = NO;
    //删除移屏手势
    [_currentView removeGestureRecognizer:leftRegcogn];
    [_currentView removeGestureRecognizer:rightRecogn];
    [_currentView removeGestureRecognizer:_pinchGester];
    [_currentView removeGestureRecognizer:_panGesture];
    
    
    [_btnPtz removeFromSuperview];
    _view_Ptz.hidden = YES;
    
    [_lblName setTextColor:[UIColor blackColor]];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    _lblName.frame = Rect(80,15,kScreenWidth-160,20);
    
    [bgTopImg removeFromSuperview];
    [bgDownImg removeFromSuperview];
    
    _switchView.frame = Rect(210, kScreenHeight-(44+60), 60, 60);
    _downHUD.frame = CGRectMake(0, kScreenHeight-50,kScreenWidth, 50);
    
    [_downHUD viewWithTag:1002].frame =  Rect(kScreenWidth/2-90 , 0, 60, 48);
    [_downHUD viewWithTag:1003].frame = Rect(kScreenWidth/2-30,  0, 60, 48);
    [_downHUD viewWithTag:1004].frame =  Rect(kScreenWidth/2+30, 0, 60, 48);
   

    
    [(UIButton*)[_downHUD viewWithTag:1002] setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    [(UIButton*)[_downHUD viewWithTag:1002] setImage:[UIImage imageNamed:@"stop_h"] forState:UIControlStateHighlighted];
    [(UIButton*)[_downHUD viewWithTag:1003] setImage:[UIImage imageNamed:@"shotopic"] forState:UIControlStateNormal];
    [(UIButton*)[_downHUD viewWithTag:1004] setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    
    _topHUD.alpha = 1.0f;
    _downHUD.alpha = 1.0f;
    [_downHUD viewWithTag:10013].backgroundColor = RGB(198, 198, 198);
    [_downHUD viewWithTag:10014].backgroundColor = [UIColor grayColor];
    
    for (int i=0; i<4; i++)
    {
        
        [((PlayControllerView*)[_array objectAtIndex:i]).mainView setFrame:((PlayControllerView*)[_array objectAtIndex:i]).mainRect];
    }
    
    [btnBD removeFromSuperview];
    [btnHD removeFromSuperview];
}

#pragma mark 点击视频框
-(void)updateClickView
{
    [self clickView:((PlayControllerView*)[_array objectAtIndex:nIndex]).mainView];
}

#pragma mark 停止选择的视频
-(void)stopCurVideo
{
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
    if (playModel)
    {
 //       [self closePlayForKey:playView.strKey];
        __weak PlayFourViewController *__weakSelf = self;
        __weak PlayControllerView *__playView = playView;
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, dispatch_get_global_queue(0, 0),
        ^{
                [__weakSelf closePlayForKey:__playView.strKey];
        });
        dispatch_group_notify(group,dispatch_get_main_queue(),
        ^{
            [__weakSelf updateClickView];
        });
        group = nil;
    }
}

#pragma mark 停止所有正在播放的视频
-(void)stopVideo
{
    _bPlay = NO;
    __weak PlayFourViewController *weakSelf =self;
    for (NSString *strKey in [_decoderInfo allKeys])
    {
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
              [weakSelf closePlayForKey:strKey];
        });
    }
}

-(void)stopAllRecord
{
    _bPlay = NO;
    __weak PlayFourViewController *weakSelf =self;
    for (NSString *strKey in [weakSelf.decoderInfo allKeys])
    {
        PlayControlModel *playModel = [_decoderInfo valueForKey:strKey];
        DLog(@"key:%@",strKey);
        if(playModel)
        {
            PlayControllerView *playView = (PlayControllerView*)[_array objectAtIndex:playModel.nPlayIndex];
            if (playView.bRecord)
            {
                DLog(@"停止录像");
                [playModel.decode recordStop];
                playView.bRecord = NO;
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    //收到内存不足警告，停止一路视频
}

-(void)dealloc
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
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

//抓拍

-(void)shotoPic
{
    ((UIButton*)[_downHUD viewWithTag:1003]).enabled = NO;
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    DLog(@"nIndex:%d",nIndex);
    PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
    if (playModel)
    {
        BOOL bReturn = [CaptureService captureToPhotoRGB:playModel.glView devName:_devModel.strDevName];
        __weak PlayControllerView *__playView = playView;
        if (bReturn)
        {
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [__playView.mainView makeToast:XCLocalized(@"captureS") duration:1.0 position:@"center"];
            });
        }
        else
        {
           dispatch_async(dispatch_get_main_queue(),
           ^{
               [__playView.mainView makeToast:XCLocalized(@"captureF") duration:1.0 position:@"center"];
           });
        }
    }
    [self performSelector:@selector(shotoPicEnableYES) withObject:nil afterDelay:1.5];
}

-(void)shotoPicEnableYES
{
    __weak UIButton* btnRecord = (UIButton*)[_downHUD viewWithTag:1003];
    dispatch_async(dispatch_get_main_queue(), ^{
        btnRecord.enabled = YES;
    });
}

#pragma mark 录像操作
//根据设备序列号或者通道好,找寻到其中的DECODER,然后就是与ipc一样的操作
-(void)recordVideo
{
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    if (playView.bRecord)
    {
        [self stopRecord:nIndex];
        __weak PlayControllerView *__play = playView;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__play.mainView makeToast:XCLocalized(@"stopRecord") duration:1.0 position:@"center"];
        });
    }
    else
    {
        _recordBtn.enabled = NO;
        playView.bRecord = YES;
        PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
        
        NSString *strPath = [CaptureService captureRecordRGB:playModel.glView];
        
        [playModel.decode recordStart:strPath name:_devModel.strDevName];
        
        _recordBtn.selected = YES;
        __weak PlayControllerView *__play = playView;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__play.mainView makeToast:XCLocalized(@"startRecord") duration:1.0 position:@"center"];
        });
        [self performSelector:@selector(recordVideoEnableYes) withObject:nil afterDelay:1.5];
    }
}
-(void)recordVideoEnableYes
{
    __weak UIButton *btnRecord = _recordBtn;
    dispatch_async(dispatch_get_main_queue(), ^{
        btnRecord.enabled = YES;
    });
}
//与开启录像操作对应
-(void)stopRecord:(int)nSelectIndex
{
    PlayControllerView *playView = [_array objectAtIndex:nSelectIndex];
    playView.bRecord = NO;
    _recordBtn.selected = NO;
    PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
    [playModel.decode recordStop];
}

-(void)connect_channelPlay:(UIButton*)sender
{
    int nChannel = (int)[sender.titleLabel.text integerValue]-1;
    [self channelPlay:nChannel];
}

#pragma mark 请求通道播放
-(void)channelPlay:(int)nChannel
{
    NSString *strChannel = [NSString stringWithFormat:@"%d",nChannel];
    __weak PlayFourViewController *weakSelf = self;
    __block NSString *__strChannel = strChannel;
    //先检测该屏幕
    PlayControllerView *playView = (PlayControllerView*)[_array objectAtIndex:(int)nIndex];
    if ([playView.strKey isEqualToString:strChannel] && playView.bPlay)//请求通道正在当前的视频框播放，不做任何操作，可以提示
    {
        return ;
    }
    PlayControlModel *_oldModel = [_decoderInfo objectForKey:playView.strKey];
    if (playView.bPlay)//如果通道正在播放
    {
        if(_oldModel.decode.fFPS!=0)
        {
            //停止视频
            //不使用独立的异步去处理
            __block NSString *__strKey = playView.strKey;
            dispatch_sync(dispatch_get_global_queue(0, 0),
            ^{
                [weakSelf closePlayForKey:__strKey];
            });
        }
        else
        {
            //提示当前视频框正在连接通道
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [weakSelf.view makeToast:XCLocalized(@"connectionDevice")];
            });
            return ;
        }
    }
    PlayControlModel *playCon = [_decoderInfo valueForKey:strChannel];
    //如果当前通道正在播放，改变播放窗口
    if (playCon)
    {
        //将glView换到另外一个mainView中   当前选中的视频框
        //将之前的playView播放方式取消
        PlayControllerView *playConOld = (PlayControllerView*)[_array objectAtIndex:playCon.nPlayIndex] ;
        playConOld.bPlay = NO;
        playConOld.strKey = @"";
        
        
        PlayControllerView *playView = ((PlayControllerView*)[_array objectAtIndex:nIndex]);
        playCon.nPlayIndex = nIndex;
        playView.bPlay = YES;
        playView.strKey = strChannel;
        playView.bRecord = playConOld.bRecord;
        
        playConOld.bRecord = NO;
        __weak PlayControllerView *__playView = playView;
        __weak PlayControlModel *__playModel = playCon;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__playView.mainView insertSubview:__playModel.glView atIndex:0];
            [__playModel.glView setFrame:__playView.mainView.bounds];
        });
        //修改切换方案，将mainRect转换区域
    }
    else
    {
        //在空的视频框连接一个通道
        __weak PlayFourViewController *__self = self;
        __block int __nIndex = nIndex;
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            [__self startNewWindow:__nIndex channel:__strChannel];
        });
    }
}

-(void)startNewWindow:(int)nPlayIndex channel:(NSString*)strChannel
{
    PlayControlModel *playModelNew = [[PlayControlModel alloc] init];
    DLog(@"新通道:%d",nPlayIndex);
    playModelNew.nPlayIndex = nPlayIndex;
    PlayControllerView *playViewNew = (PlayControllerView *)[_array objectAtIndex:playModelNew.nPlayIndex];
    
    playViewNew.bPlay = YES;
    playViewNew.strKey = strChannel;
    
    [_decoderInfo setValue:playModelNew forKey:strChannel];
    __weak NSString *__strNO = _strNO;
    __block NSString *__strChannel = strChannel;
    __weak PlayControllerView *__playView = playViewNew;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__playView.mainView makeToastActivity];
    });
    __weak PlayFourViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
          [weakSelf startPlayWithNO:__strNO channel:__strChannel codeType:2];
    });
    
}

#pragma mark 关闭视频
-(void)closePlayForKey:(NSString *)strKey
{
    PlayControlModel *playModel = [_decoderInfo valueForKey:strKey];
    DLog(@"key:%@",strKey);
    if(playModel)
    {
        PlayControllerView *playView = (PlayControllerView*)[_array objectAtIndex:playModel.nPlayIndex];
        if (playView.bRecord)
        {
            DLog(@"停止录像");
            [playModel.decode recordStop];
            playView.bRecord = NO;
        }
        playView.bPlay = NO;
        [playModel.decode releaseDecode];
        __weak PlayControllerView *__playView = playView;
        __weak UIImageView *__glView = playModel.glView;
        dispatch_async(dispatch_get_main_queue(),^{
            [__glView removeFromSuperview];
            [__playView.mainView hideToastActivity];
        });
        [NSThread sleepForTimeInterval:0.3f];
        playModel.decode = nil;
        playModel.glView = nil;
        [_decoderInfo removeObjectForKey:strKey];
        playView.strKey = nil;
        DLog(@"关闭一路");
    }
}

-(void)clickView:(id)sender
{
    VideoView *view = (VideoView*)sender;
    [_borderLabel setFrame:view.frame];
    nIndex = (int)view.nCursel;
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
    if(![UserInfo sharedUserInfo].bGuess && playView.bPlay && playModel && playModel.glView)
    {
        ((UIButton*)[_downHUD viewWithTag:1002]).enabled = YES;
        ((UIButton*)[_downHUD viewWithTag:1003]).enabled = YES;
        _recordBtn.enabled = YES;
        _recordBtn.selected = playView.bRecord ? YES : NO;
        ((UIButton*)[_downHUD viewWithTag:1005]).enabled = YES;
        if(playModel.decode.nCodeType==1)
        {
            [btnBD setEnabled:YES];
            [btnHD setEnabled:NO];
        }
        else if(playModel.decode.nCodeType == 2 )
        {
            [btnBD setEnabled:NO];
            [btnHD setEnabled:YES];
        }
    }
    else
    {
        ((UIButton*)[_downHUD viewWithTag:1002]).enabled = NO;
        ((UIButton*)[_downHUD viewWithTag:1003]).enabled = NO;
        _recordBtn.enabled = NO;
        ((UIButton*)[_downHUD viewWithTag:1005]).enabled = NO;
        [btnBD setEnabled:NO];
        [btnHD setEnabled:NO];
    }
    if (bScreen)
    {
        if (!playView.bPlay)
        {
            _downHUD.alpha = 1;
            _topHUD.alpha = 1;
        }
        else
        {
           _downHUD.alpha = _downHUD.alpha ? 0 : 1;
           _topHUD.alpha = _topHUD.alpha ? 0 : 1;
        }
    }
}
-(void)doubleClickVideo:(id)sender
{
    VideoView *view = (VideoView*)sender;
    int nTemp = (int)view.nCursel;
    PlayControllerView* playView = [_array objectAtIndex:nTemp];
    PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
    if (playView.bPlay)
    {
        for (int i=0; i<4; i++)
        {
            if(i!=nTemp)
            {
                [((PlayControllerView*)[_array objectAtIndex:i]).mainView setHidden:!bFull];
            }
        }
        if (!bFull)
        {
            
        }
        else
        {
            __weak PlayControllerView *_playView = playView;
            __weak PlayControlModel *_playModel = playModel;
            __weak PlayFourViewController *_weakSelf = self;
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [_playView.mainView setFrame:_playView.mainRect];
                [_playModel.glView removeFromSuperview];
                [_playView.mainView insertSubview:_playModel.glView atIndex:0];
                [_weakSelf.borderLabel setFrame:view.frame];
            });
        }
        _currentView = playView.mainView;
        [self fullPlayMode];
        _borderLabel.hidden = !bFull;
        bFull = !bFull;
    }
    else
    {
        if (bFull)
        {
            for (int i=0; i<4; i++)
            {
                [((PlayControllerView*)[_array objectAtIndex:i]).mainView setHidden:NO];
            }
            __weak PlayControllerView *_playView = playView;
            __weak PlayControlModel *_playModel = playModel;
            __weak PlayFourViewController *_weakSelf = self;
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [_playView.mainView setFrame:_playView.mainRect];
                [_playModel.glView removeFromSuperview];
                [_playView.mainView insertSubview:_playModel.glView atIndex:0];
                [_weakSelf.borderLabel setFrame:view.frame];
            });
            [self fullPlayMode];
            _borderLabel.hidden = !bFull;
            bFull = !bFull;
        }
    }
}

-(void)setOrientation1:(id)sender
{
    DLog(@"111111111111");
}


#pragma mark 全屏与四屏切换，设置frame与bounds
-(void)fullPlayMode
{
    if (!bScreen)//NO状态表示当前竖屏，需要转换成横屏
    {
        CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        [[UIDevice currentDevice] setValue: [NSNumber numberWithInteger:UIDeviceOrientationLandscapeRight] forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        CGRect frame = [UIScreen mainScreen].bounds;
        CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width/2), frame.origin.y + ceil(frame.size.height/2));
        self.view.center = center;
        self.view.transform = [self transformView];
        self.view.bounds = Rect(0, 0, frame.size.height, frame.size.width);
        [UIView commitAnimations];
        bScreen = !bScreen;
    }
    else
    {
        [self setHorizontal];
        bScreen = !bScreen;
    }
}

-(void)setHorizontal
{
    [[UIDevice currentDevice] setValue: [NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = [UIScreen mainScreen].bounds;
    CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width/2), frame.origin.y + ceil(frame.size.height/2));
    self.view.center = center;
    self.view.transform = [self transformView];
    self.view.bounds = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    [UIView commitAnimations];
}

- (void)doneDidTouch: (id) sender
{
    bExit = YES;
    __weak PlayFourViewController *__weakSelf = self;
    if (bScreen)
    {
        [self setHorizontal];
    }
    [self dismissViewControllerAnimated:YES completion:
     ^{
         [__weakSelf stopVideo];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    }];
}

#pragma mark 隐藏status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(CGAffineTransform)transformView
{
    if (!bScreen)
    {
        return CGAffineTransformMakeRotation(M_PI/2);
    }
    else
    {
        return CGAffineTransformIdentity;
    }
}


#pragma mark 加入重力支持
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!bScreen)//bScreen 旋转前判断状态：NO 表示  竖屏   YES 表示横屏      在LayoutSubviews之后与前一结论相反
    {
        //翻转为竖屏时
        [self setHorizontalFrame];
    }else
    {
        //翻转为横屏时
        [self setVerticalFrame];
    }
}

-(void)switchBTNVideoCodeInfo:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    int nType = 0;
    if(btn.tag==1005)
    {
        nType= 1;
        UIButton *btnSender = (UIButton*)[_downHUD viewWithTag:1006];
        btnSender.enabled = NO;
    }
    else if(btn.tag == 1006)
    {
        nType = 2;
        UIButton *btnSender = (UIButton*)[_downHUD viewWithTag:1005];
        btnSender.enabled = NO;
    }
//    [self switchVideoCode:nType];
//    [self set]
    btn.enabled = NO;
}

#pragma mark 全屏手势操作
- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.direction==UISwipeGestureRecognizerDirectionLeft)
    {
        [self switchFullVideo:YES];
    }
    else if (recognizer.direction==UISwipeGestureRecognizerDirectionRight)
    {
        [self switchFullVideo:NO];
    }
    _topHUD.alpha = 1.0f;
    _downHUD.alpha = 1.0f;
}

#pragma mark 全屏与四屏画面切换
-(void)switchFullVideo:(BOOL)bFlag
{
    bNewStatus = NO;
    int nTemp = bFlag ? 1 : -1;
    while (YES)
    {
        if (nIndex+nTemp == 4 || nIndex+nTemp < 0)
        {
            break;
        }
        PlayControllerView *playView = (PlayControllerView *)[_array objectAtIndex:nIndex+nTemp];
        if (playView.bPlay)
        {
        
            PlayControllerView *playOldView = (PlayControllerView *)[_array objectAtIndex:nIndex];
            playOldView.mainView.hidden = YES;
      
            //移除手势
            [playOldView.mainView removeGestureRecognizer:leftRegcogn];
            [playOldView.mainView removeGestureRecognizer:rightRecogn];
            [playOldView.mainView removeGestureRecognizer:_pinchGester];
            
            //设置当前frame位置
            _currentView = playView.mainView ;
            [playView.mainView setHidden:NO];
            [self clickView:playView.mainView];
            CGFloat width,height;
            if (IOS_SYSTEM_8) {
                width = kScreenWidth;
                height = kScreenHeight;
            }
            else
            {
                width = kScreenHeight;
                height = kScreenWidth;
            }
            //设置全屏位置
            [playView.mainView setFrame:Rect(0, 0, width, height)];
            break;
        }
        bFlag ? nTemp++ : nTemp--;
    }
}

#pragma mark 显示ptz
-(void)showPtzView
{
    _view_Ptz.hidden = !_view_Ptz.hidden;
}
#pragma mark ptz操作委托
-(void)ptzView:(int)ptzCmd
{
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
    if (playModel && playModel.decode)
    {
        DLog(@"发送指令:nPtzCmd:%d",ptzCmd);
        [playModel.decode sendPtzCmd:ptzCmd];
    }
}

#pragma mark 对应一个空的视频框，连接该视频
-(void)startPlayWithNO:(NSString*)strNO channel:(NSString*)strKey codeType:(int)nCodeType
{
    PlayControlModel *playModel = [_decoderInfo valueForKey:strKey];
    if (!playModel)//如果不存在，创建对象，进行连接
    {
        playModel = [[PlayControlModel alloc] init];
        [_decoderInfo setValue:playModel forKey:strKey];
    }
    playModel.decode = [[XCDecoderNew alloc] initWithFormat:KxVideoFrameFormatRGB codeType:nCodeType];
    
    //多屏播放控制器
    __weak PlayFourViewController *weakSelf = self;
    //序列号
    __weak NSString *__strNO = strNO;
    //解码器
    __weak XCDecoderNew *weakdecode = playModel.decode;
    //通道字符串
    __block NSString *__strChannel = strKey;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
          [weakdecode startConnectWithChan:__strNO channel:[__strChannel intValue]];
    });
    _bPlay = YES;
    playModel.nPlayIndex = nIndex;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        while (!weakdecode.fFPS)
        {
            [NSThread sleepForTimeInterval:0.2f];
            if (!weakSelf.bPlay)
            {
                return ;
            }
        }
        [weakSelf startNewPlay:__strChannel];
        [weakSelf initGlViewWithNO:__strNO channel:__strChannel];
    });
}

#pragma mark 初始化显示
-(void)initGlViewWithNO:(NSString *)strNO channel:(NSString*)strKey
{
    PlayControlModel *playModel = [_decoderInfo valueForKey:strKey];
    
    PlayControllerView *playView = (PlayControllerView*)[_array objectAtIndex:(int)playModel.nPlayIndex];
    
    playView.strKey = strKey;
    
    playView.bPlay = YES;
    
    playModel.glView = [[UIImageView alloc] initWithFrame:playView.mainView.bounds];
    
    playModel.glView.contentMode = UIViewContentModeScaleToFill;
    
    playModel.glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    __weak PlayControllerView *__weakPlay = playView;
    __weak PlayControlModel *_playModel = playModel;
    __weak PlayControllerView *_playView = playView;
    __weak PlayFourViewController *_weakSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [_playView.mainView insertSubview:_playModel.glView atIndex:0];
        [__weakPlay.mainView hideToastActivity];
        [_weakSelf updateClickView];
    });
}

#pragma mark 新增方法  startPlay
-(void)startNewPlay:(NSString *)strKey
{
    PlayControlModel *playInfo = [_decoderInfo valueForKey:strKey];
    playInfo.decode.playing = YES;
    playInfo.videoFrame = [NSMutableArray array];
    
    __weak PlayFourViewController *__weakSelf = self;
    __block NSString *__strKey = strKey;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__weakSelf playMovieWithChannel:__strKey];
    });
}
#pragma mark 解码触发
-(void)asyncDecoder:(NSString*)strKey
{
    PlayControlModel *playInfo = [_decoderInfo valueForKey:strKey];
    if (playInfo.bDecoding || !playInfo.decode.playing) {
        return;
    }
    playInfo.bDecoding = YES;
    __weak PlayControlModel *__playInfo = playInfo;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
           BOOL good = YES;
           while (good && __playInfo.decode.playing)
           {
               good = NO;
               @autoreleasepool
               {
                   NSArray *frames = [__playInfo.decode decodeFrames];
                   if(frames.count>0)
                   {
                       @synchronized(__playInfo.videoFrame)
                       {
                           for (KxMovieFrame *frame in frames)
                           {
                               if (frame.type == KxMovieFrameTypeVideo)
                               {
                                   [__playInfo.videoFrame addObject:frame];
                               }
                           }
                       }
                   }
                   frames = nil;
               }
           }
           __playInfo.bDecoding = NO;
    });
    
}

#pragma mark 持续播放视频的操作

-(void)playMovieWithChannel:(NSString*)strKey
{
    PlayControlModel *playInfo = [_decoderInfo valueForKey:strKey];
   if(playInfo.decode.playing)//判断解码器状态
    {
        CGFloat interval = 0;
        KxVideoFrame *frame = nil;
        @synchronized(playInfo.videoFrame)
        {
            if(playInfo.videoFrame.count>0)
            {
                frame = playInfo.videoFrame[0];
                [playInfo.videoFrame removeObjectAtIndex:0];
            }
        }
        if (frame)
        {
            KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
            __weak PlayControlModel *__playInfo = playInfo;
            UIImage *rgbImage = rgbFrame.asImage;
            __weak UIImage *__rgbImage = rgbImage;
            dispatch_sync(dispatch_get_main_queue(),
            ^{
                 [__playInfo.glView setImage:__rgbImage];
            });
            interval = frame.duration*0.4;
            rgbFrame = nil;
            frame = nil;
        }
        __weak PlayFourViewController *weakSelf = self;
        __block NSString* __strKey = strKey;
        if (playInfo.videoFrame.count==0)//解码,如果已有不够
        {
            [self asyncDecoder:strKey];
        }
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.02 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)//播放线程重用
        {
            [weakSelf playMovieWithChannel:__strKey];
        });
    }
}


-(void)panEvent:(UIPanGestureRecognizer*)sender
{
    if ([sender state]== UIGestureRecognizerStateBegan)
    {
        CGPoint curPoint = [sender locationInView:self.view];
        lastX = curPoint.x;
        lastY = curPoint.y;
       return ;
    }
    CGPoint curPoint = [sender locationInView:self.view];
    CGFloat frameX = (_currentView.x + (curPoint.x-lastX)) > 0 ? 0 : (abs(_currentView.x+(curPoint.x-lastX))+fWidth >= _currentView.width ? -(_currentView.width-fWidth) : (_currentView.x+(curPoint.x-lastX)));
    CGFloat frameY =(_currentView.y + (curPoint.y-lastY))>0?0: (abs(_currentView.y+(curPoint.y-lastY))+fHeight >= _currentView.height ? -(_currentView.height-fHeight) : (_currentView.y+(curPoint.y-lastY)));
    _currentView.frame = Rect(frameX,frameY , _currentView.width, _currentView.height);
    lastX = curPoint.x;
    lastY = curPoint.y;
}

-(void)pinchEvent:(UIPinchGestureRecognizer*)sender
{
    DLog(@"点击事件");
    if([sender state] == UIGestureRecognizerStateBegan) {
     //   lastScale = 1.0;
        return;
    }
    CGFloat glWidth = _currentView.frame.size.width;
    CGFloat glHeight = _currentView.frame.size.height;
    CGFloat fScale = [sender scale];
    
    if (_currentView.frame.size.width * [sender scale] <= fWidth)
    {
        _currentView.frame = Rect(0, 0, fWidth, fHeight);
       [_currentView removeGestureRecognizer:_panGesture];
    }
    else
    {
        [_currentView addGestureRecognizer:_panGesture];
        CGFloat nowWidth = glWidth*fScale>fWidth*4?fWidth*4:glWidth*fScale;
        CGFloat nowHeight =glHeight*fScale >fHeight* 4?fHeight*4:glHeight*fScale;
        _currentView.frame = Rect(fWidth/2 - nowWidth/2,fHeight/2- nowHeight/2,nowWidth,nowHeight);
    }
}
@end
