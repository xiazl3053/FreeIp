//
//  XCPlayerController.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-14.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "PlayP2PViewController.h"
#import "XCDecoder.h"
#import "KxMovieGLView.h"
#import "XCNotification.h"
#import "devInfoMacro.h"
#import "IndexViewController.h"
#import "CustomNaviBarView.h"
#import "ProgressHUD.h"
#import "Toast+UIView.h"
#import "CaptureService.h"
#import "UserInfo.h"
#import "PTZView.h"
#import "UIView+Extension.h"
#define MAX_FRAME  6
#define MIN_FRAME  1
#define  kMAXBUFFEREDDURATION_IPC 0.05
#define  kMINBUFFEREDDURATION_IPC 0.02

@interface PlayP2PViewController()<PTZViewDelegate,UIScrollViewDelegate>
{
    dispatch_queue_t _dispatchQueue;
    BOOL                bFirst;
    UIActivityIndicatorView  *viewActivity;
    UIView              *_topHUD;
    UIView              *_downHUD;
    UIButton            *_doneButton;
    UITapGestureRecognizer *_doubleRecognizer;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    UIPinchGestureRecognizer *pinchGesture;
    UIPanGestureRecognizer *_panGesture;
    
    BOOL    _hiddenHUD;
    CGFloat fWidth,fHeight;
    CGFloat _bufferedDuration;
    CGFloat _minBufferedDuration;
    CGFloat _maxBufferedDuration;
    NSTimeInterval      _tickCorrectionTime;
    NSTimeInterval      _tickCorrectionPosition;
    NSUInteger    _tickCounter;
    UILabel *_progressLabel;
    CGFloat lastScale;
    
    int nPlayStatus;
    NSUInteger _nFormat;

    CGRect frameCenter;
    BOOL bIsFull;
    BOOL bRecord;
    BOOL bStart;
    BOOL _buffered;
    int nWidth ;
    int nHeight ;
    BOOL bScreen;
    UILabel *_lblName;
    CGFloat _movieDuration;
    CGFloat _startDuration;
    UIButton *btnSwitch;
    
    UIImageView *downViewBg;
    UIImageView *topViewBg;
    
    UIView *full_TopView;
    UIView *full_DownView;
    
    UIButton *btnPlayHd;
    UIButton *btnPlayBd;
    
    UIButton *btnPtz;
    
    UIImageView *line1;
    UIImageView *line2;
    UIImageView *line3;
    UIImageView *line4;
    CGFloat lastX;
    CGFloat lastY;
    NSInteger nCount;
    BOOL bExit;
    
}
@property (nonatomic,assign) NSInteger nCodeType;
@property (nonatomic) BOOL decoding;
@property (nonatomic,strong) XCDecoder *decoder;
@property (nonatomic,strong) NSString *strNO;
@property (readwrite) BOOL playing;
@property (nonatomic,strong) NSString *strName;
@property (nonatomic,strong) KxMovieGLView *glView;
@property (nonatomic,strong) NSMutableArray *videoFrames;
@property (nonatomic,strong) UIButton *btnPlay;
@property (nonatomic,strong) UIButton *btnHD;
@property (nonatomic,strong) UIButton *btnBD;
@property (nonatomic,strong) UIButton *btnPhoto;
@property (nonatomic,strong) UIButton *btnRecord;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) PTZView *view_Ptz;


@end

@implementation PlayP2PViewController

-(void)dealloc
{
    [_videoFrames removeAllObjects];
    [_tapGestureRecognizer removeTarget:self action:@selector(handleTapNew:)];//修改成新的
    [_doubleRecognizer removeTarget:self action:@selector(handleTapNew:)];//修改成新的
    
    [_view_Ptz removeFromSuperview];
    [_btnPhoto removeFromSuperview];
    [_btnRecord removeFromSuperview];
    
    [_btnBD removeFromSuperview];
    [_btnHD removeFromSuperview];
    
    [_glView removeFromSuperview];
    [_downHUD removeFromSuperview];
    [_topHUD removeFromSuperview];
    [_lblName removeFromSuperview];
    [_btnPlay removeFromSuperview];
    
    _videoFrames = nil;
    _decoder = nil;
    _glView = nil;
    _dispatchQueue = nil;
    _doneButton = nil;
    _topHUD = nil;
    _downHUD = nil;
    _strNO = nil;
    _strName = nil;
}


/**
 *  初始化方法
 *
 *  @param nsNO    设备序列号
 *  @param strName 设备名
 *  @param nFormat 视频数据显示方式
 *
 *  @return self
 */
-(id)initWithNO:(NSString*)nsNO name:(NSString*)strName format:(NSUInteger)nFormat
{
    self = [super init];
    if (self)
    {
        self.strNO = [nsNO copy];
        _nFormat = nFormat;
        _strName = [strName copy];
    }
    return self;
}

-(void)loadView
{
    [super loadView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];//隐藏status bar
    [self initToolBar];
    lastScale = 1.0f;
    _tapGestureRecognizer.numberOfTapsRequired = 1; // 单击
    _doubleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapNew:)];
    _doubleRecognizer.numberOfTapsRequired = 2; // 双击
    bExit = NO;
    nCount = 0;
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapNew:)];
//    [_tapGestureRecognizer requireGestureRecognizerToFail:_doubleRecognizer];
    pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchEvent:)];
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
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
    CGFloat frameX = (_glView.x + (curPoint.x-lastX)) > 0 ? 0 : (abs(_glView.x+(curPoint.x-lastX))+fWidth >= _glView.width ? -(_glView.width-fWidth) : (_glView.x+(curPoint.x-lastX)));
    CGFloat frameY =(_glView.y + (curPoint.y-lastY))>0?0: (abs(_glView.y+(curPoint.y-lastY))+fHeight >= _glView.height ? -(_glView.height-fHeight) : (_glView.y+(curPoint.y-lastY)));
    _glView.frame = Rect(frameX,frameY , _glView.width, _glView.height);
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
    CGFloat glWidth = _glView.frame.size.width;
    CGFloat glHeight = _glView.frame.size.height;
    CGFloat fScale = 0;
    if ([sender scale]>1)
    {
        fScale = 1.011;
    }
    else
    {
        fScale = 0.99;
    }
    if (_glView.frame.size.width * [sender scale] <= fWidth)
    {
        lastScale = 1.0f;
        _glView.frame = Rect(0, 0, fWidth, fHeight);
        [_glView removeGestureRecognizer:_panGesture];
    }
    else
    {
        [_glView addGestureRecognizer:_panGesture];
        lastScale = 1.5f;
        CGPoint point = [sender locationInView:self.view];
        DLog(@"point:%f--%f",point.x,point.y);
        CGFloat nowWidth = glWidth*fScale>fWidth*4?fWidth*4:glWidth*fScale;
        CGFloat nowHeight =glHeight*fScale >fHeight* 4?fHeight*4:glHeight*fScale;
        
        _glView.frame = Rect(fWidth/2 - nowWidth/2,fHeight/2- nowHeight/2,nowWidth,nowHeight);
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    bIsFull = NO;
    _dispatchQueue = dispatch_queue_create("decoder", DISPATCH_QUEUE_SERIAL);
    _videoFrames    = [NSMutableArray array];
    _minBufferedDuration = 0.1;
    _maxBufferedDuration = 0.34;
    bRecord = NO;
    _hiddenHUD = NO;
    nWidth = 0;
    nHeight = 0;
    [self playVideo];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setNewVerticalFrame];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connect_p2p_fail:) name:NSCONNECT_P2P_FAIL_VC object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enter_background) name:NS_APPLITION_ENTER_BACK object:nil];
}

/*
 *  进入后台设置,销毁P2P连接的SDK,停止播放
 */
-(void)enter_background
{
    [_decoder destorySDK];
    dispatch_group_t group = dispatch_group_create();
    __weak PlayP2PViewController *weakSelf = self;
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        [weakSelf stopVideo];
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    group = nil;
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [ProgressHUD dismiss];
}

/**
 *  点击事件
 *
 *  @param tapGesture 手势事件
 */
-(void)handleTapNew:(UITapGestureRecognizer*)tapGesture
{
    if (tapGesture.state == UIGestureRecognizerStateEnded)
    {
        CGPoint point = [tapGesture locationInView:self.view];
        if (point.y < 40 || point.y > _downHUD.frame.origin.y)
        {
            return ;
        }
        if (tapGesture == _tapGestureRecognizer)
        {
            [self showHUD: _hiddenHUD];
        }
        else if (tapGesture == _doubleRecognizer)
        {

        }
    }

}


- (void) showHUD: (BOOL) show
{
    _hiddenHUD = !show;
    [self showToolBar];
}

-(void)showToolBar
{
    _topHUD.alpha = _hiddenHUD ? 0 :0.8f;
    _downHUD.alpha = _hiddenHUD ? 0 : 0.8f;
}
-(void)initToolBar
{
    //新加入scrollview
    
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenWidth,49)];
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topHUD];
    _topHUD.alpha = 1;
    
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, _topHUD.frame.size.height-0.2, kScreenWidth, 0.1)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, _topHUD.frame.size.height-0.1, kScreenWidth, 0.1)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [_topHUD addSubview:sLine1];
    [_topHUD addSubview:sLine2];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,15,kScreenWidth-60,20)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:_strName];
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    
    [_lblName setTextColor:[UIColor blackColor]];
    [_topHUD addSubview:_lblName];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    _doneButton.frame = CGRectMake(5,2.5,44,44);
    _doneButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_topHUD addSubview:_doneButton];
    
    _progressLabel = [[UILabel alloc] initWithFrame:Rect(0, 0, 60, 20)];
    [_progressLabel setTextAlignment:NSTextAlignmentCenter];
    [_progressLabel setTextColor:[UIColor redColor]];
    [_progressLabel setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [_progressLabel setAlpha:0.6f];
    
    _downHUD = [[UIView alloc] initWithFrame:Rect(0, kScreenHeight-50+HEIGHT_MENU_VIEW(20, 0),kScreenWidth, 50)];
    _downHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_downHUD];
    _downHUD.alpha = 1;
    [_downHUD setBackgroundColor:[UIColor clearColor]];
    
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
    
    
    _btnPlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnPlay setImage:[UIImage imageNamed:@"full_play"] forState:UIControlStateNormal];
    [_btnPlay addTarget:self action:@selector(playWithAction:) forControlEvents:UIControlEventTouchUpInside];
    [_btnPlay setImage:[UIImage imageNamed:@"full_stop"] forState:UIControlStateSelected];
    _btnPlay.tag = 1001;
    
    _btnPhoto = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnPhoto setImage:[UIImage imageNamed:@"full_snap"] forState:UIControlStateNormal];
    [_btnPhoto setImage:[UIImage imageNamed:@"shotopic_h"] forState:UIControlStateHighlighted];
    [_btnPhoto addTarget:self action:@selector(shotoPic:) forControlEvents:UIControlEventTouchUpInside];
    _btnPhoto.tag = 1003;
    
    _btnRecord = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnRecord setImage:[UIImage imageNamed:@"full_record"] forState:UIControlStateNormal];
    [_btnRecord addTarget:self action:@selector(recordVideo) forControlEvents:UIControlEventTouchUpInside];
    [_btnRecord setImage:[UIImage imageNamed:@"record_sel"] forState:UIControlStateSelected];
    [_btnRecord setImage:[UIImage imageNamed:@"record_select"] forState:UIControlStateHighlighted];
    _btnRecord.tag = 1004;
    
    _btnBD = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnBD setImage:[UIImage imageNamed:@"play_bd"] forState:UIControlStateNormal];
    [_btnBD addTarget:self action:@selector(switchVideoCodeInfo:) forControlEvents:UIControlEventTouchUpInside];
    _btnBD.tag = 1005;
    [_downHUD addSubview:_btnBD];
    _btnBD.frame = Rect(180, 1, 60, 48);
    
    _btnHD = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnHD setImage:[UIImage imageNamed:@"play_hd"] forState:UIControlStateNormal];
    [_btnHD addTarget:self action:@selector(switchVideoCodeInfo:) forControlEvents:UIControlEventTouchUpInside];
    _btnHD.tag = 1006;
    _btnHD.frame = Rect(240, 1, 60, 48);
    [_downHUD addSubview:_btnHD];

    [_btnPlay setEnabled:NO];
    [_btnPhoto setEnabled:NO];
    [_btnRecord  setEnabled:NO];
    [_btnBD setEnabled:NO];
    [_btnHD setEnabled:NO];
    
    [_downHUD addSubview:_btnPlay];
    [_downHUD addSubview:_btnPhoto];
    [_downHUD addSubview:_btnRecord];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    _view_Ptz = [[PTZView alloc] initWithFrame:Rect(0, 0, 164, 114)];
    [self.view addSubview:_view_Ptz];
    _view_Ptz.hidden = YES;
    _view_Ptz.delegate = self;
    
    topViewBg = [[UIImageView alloc] initWithFrame:_topHUD.bounds];
    [topViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    
    downViewBg = [[UIImageView alloc] initWithFrame:_downHUD.bounds];
    [downViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    
    btnPtz = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnPtz setImage:[UIImage imageNamed:@"ptz_control"] forState:UIControlStateNormal];
    line1 = [self createImageViewLine];
    line2 = [self createImageViewLine];
    line3 = [self createImageViewLine];
    line4 = [self createImageViewLine];
  //  [self setNewVerticalFrame];
}


-(UIImageView *)createImageViewLine
{
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"full_line"]];
}

/**
 *  视频切换
 *
 *  @param sender <#sender description#>
 */
-(void)switchVideoCodeInfo:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    int nType = 0;
    if(btn.tag==1005)
    {
        nType= 2;
        _btnHD.enabled = NO;
    }
    else if(btn.tag == 1006)
    {
        nType = 1;
        _btnBD.enabled = NO;
    }
    [self switchVideoCode:nType];
    [self setPlayMode:NO];
    btn.enabled = NO;
}

#pragma mark - actions
- (void)doneDidTouch: (id) sender
{
    bExit = YES;
    [self stopVideo];
    [self dismissViewControllerAnimated:YES completion:
    ^{
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    }];
}

-(void)connect_p2p_fail:(NSNotification*)notify
{
    NSString *strInfo = [notify object];
    __weak NSString *__strInfo = strInfo;
    __weak PlayP2PViewController *__weakSelf = self;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        [__weakSelf stopVideo];
    });
    dispatch_group_async(group,dispatch_get_main_queue(),
    ^{
        [ProgressHUD dismiss];
        [__weakSelf.view makeToast:__strInfo duration:1.0f position:@"center"];
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    nCount++;
    if (nCount<=3 && !bExit)
    {
        DLog(@"正在第%li次重连",(long)nCount);
        __weak PlayP2PViewController *__weakSelf = self;
        //bScreen)//bScreen no 竖屏   yes 横屏
        if (IOS_SYSTEM_8)
        {
            dispatch_group_async(group,dispatch_get_main_queue(),
            ^{
               [ProgressHUD show:XCLocalized(@"reconnect") viewInfo:__weakSelf.view];
            });
        }
        else
        {
            dispatch_group_async(group,dispatch_get_main_queue(), ^{
                [ProgressHUD showPlayRight:XCLocalized(@"reconnect") viewInfo:__weakSelf.view];
            });
        }
        dispatch_group_async(group,dispatch_get_global_queue(0, 0),
        ^{
           [__weakSelf decoderInfo];
        });
        nPlayStatus = 1;
    }
}

-(void)decoderInfo
{
    _playing = YES;
    if([UserInfo sharedUserInfo].bGuess)
    {
        _decoder = [[XCDecoder alloc] initWithNO:_strNO format:_nFormat videoFormat:KxVideoFrameFormatYUV codeType:1];
        _nCodeType = 1;
    }
    else
    {
        _decoder = [[XCDecoder alloc] initWithNO:_strNO format:_nFormat videoFormat:KxVideoFrameFormatYUV];
        _nCodeType = 2;
    }
    while(_decoder.fps==0)
    {
        if (!_playing)
        {
            nPlayStatus = 0;
            return ;
        }
        [NSThread sleepForTimeInterval:0.3f];
        
    }
    _playing = NO;
    __weak PlayP2PViewController *wearSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [wearSelf play];
        [wearSelf initGlView];
    });
   [UIApplication sharedApplication].idleTimerDisabled = YES;
}


-(void)decoderTran
{
    _playing = YES;
    XCDecoder *decoder = [[XCDecoder alloc] initWithNO:_strNO format:2 videoFormat:KxVideoFrameFormatYUV codeType:_nCodeType];
    while(decoder.fps==0)
    {
        if (!_playing)
        {
            nPlayStatus = 0;
            return ;
        }
        [NSThread sleepForTimeInterval:0.3f];
    }
    _playing = NO;
    __weak PlayP2PViewController *wearSelf = self;
    _decoder = decoder;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [wearSelf.btnPlay setSelected:YES];
        [wearSelf play];
        [wearSelf initGlView];
    });
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

-(void)initGlView
{
    if (UIInterfaceOrientationPortrait == [UIApplication sharedApplication].statusBarOrientation)
    {
        //16:9   320 ：240
        CGFloat fTempHeight = kScreenWidth/4*3;
        frameCenter = Rect(0,kScreenHeight/2-fTempHeight/2, kScreenWidth, fTempHeight);
    }
    else
    {
        if(IOS_SYSTEM_8)
        {
            frameCenter = Rect(0, 0,kScreenWidth,kScreenHeight);
        }
        else
        {
            frameCenter = Rect(0, 0,kScreenHeight,kScreenWidth);
        }
    }
    //4:3  16:10
    _glView = [[KxMovieGLView alloc] initWithFrame:frameCenter decoder:_decoder];
    _glView.contentMode = UIViewContentModeScaleToFill;//UIViewContentModeScaleAspectFill;UIViewContentModeScaleAspectFit
    _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.view insertSubview:_glView atIndex:0];
    [_glView addGestureRecognizer:_tapGestureRecognizer];
    [_glView addGestureRecognizer:pinchGesture];
    [_glView setUserInteractionEnabled:YES];
    [_glView addGestureRecognizer:_panGesture];
    [self.btnPlay setEnabled:YES];
    
    [self.btnPlay setSelected:YES];
    [self setPlayMode:YES];
}

- (void) play
{
    if (_playing)
    {
        return;
    }
    __weak PlayP2PViewController *wearSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [ProgressHUD dismiss];
    });
    _decoding = NO;
    _tickCounter = 0;
    _tickCorrectionTime = 0;
    _playing = YES;    
    [self asyncDecodeFrames];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (1.0/100) * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
    {
        if(wearSelf.playing)
        {
            [wearSelf tick];
        }
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [wearSelf setPlayMode:YES];
    });
}
-(void)tick
{
    CGFloat interval = 0;
    interval = [self presentFrame]*0.2;
    if (_playing)
    {
        const NSUInteger leftFrames = _videoFrames.count;
        if (leftFrames==0)
        {
            [self asyncDecodeFrames];
        }
        if (_decoder.isEOF && _bufferedDuration == 0)
        {
            return ;
        }
        __weak PlayP2PViewController *wearSelf = self;
        const NSTimeInterval time = MAX(interval, 0.025);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
        {
            [wearSelf tick];
        });
    }
    else
    {
        DLog(@"出去了");
        return;
    }
    if ((_tickCounter++ % 3) == 0)
    {
        __weak PlayP2PViewController *__weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [__weakSelf updateHUD];
        });
    }
}
-(NSString*)formatTimeInterval:(CGFloat) seconds
{
    seconds = MAX(0, seconds);
    int s = seconds;
    int m = s / 60;
    int h = m / 60;
    s = s % 60;
    m = m % 60;
    return [NSString stringWithFormat:@"%d:%0.2d:%0.2d",h,m,s];
}
//1.原通道隐藏
//2.打开已经播放  --对通道  --对正在播放
//3.全屏显示

-(void)updateHUD
{
    if(!bRecord)
    {
        return;
    }
    const CGFloat position = _movieDuration-_startDuration;// -_decoder.startTime;
    NSString *strTime = [self formatTimeInterval:position];
    __weak UILabel *__timeLabel = _progressLabel;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        __timeLabel.text = strTime;
    });
}
-(CGFloat)tickCorrection
{
    if (_buffered)
        return 0;
    const NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (!_tickCorrectionTime)
    {
        _tickCorrectionTime = now;
        _tickCorrectionPosition = _movieDuration;
        return 0;
    }
    NSTimeInterval dPosition = _movieDuration - _tickCorrectionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPosition - dTime;
    if (correction > 1.f || correction < -1.f)
    {
        correction = 0;
        _tickCorrectionTime = 0;
    }
    return correction;
}
- (CGFloat) presentFrame
{
    CGFloat interval = 0;
    KxVideoFrame *frame;
    @synchronized(_videoFrames)
    {
        if (_videoFrames.count > 0) {
            frame = _videoFrames[0];
            [_videoFrames removeObjectAtIndex:0];
        }
    }
    if (frame)
    {
        __weak PlayP2PViewController *__weakSelf = self;
        __weak KxVideoFrame *__frame = frame;
        dispatch_sync(dispatch_get_main_queue(),
        ^{
            [__weakSelf presentVideoFrame:__frame];
        });
        _movieDuration = frame.position;
        interval = frame.duration;
        _bufferedDuration -= frame.duration;
        frame = nil;
        
    }
    return interval;
}

- (CGFloat)presentVideoFrame: (KxVideoFrame *) frame
{
    //修改成OPENGL 贴图RGB与YUV两种方式
    [_glView render:frame];
    return 0;
}

-(void)asyncDecodeFrames
{
    if (self.decoding)
        return;
    
    __weak PlayP2PViewController *wearSelf = self;
    self.decoding = YES;
    dispatch_async(_dispatchQueue,
    ^{
        BOOL good = YES;
        while (good && wearSelf.playing)
        {
            good = NO;
            @autoreleasepool
            {
                if (!wearSelf.playing)
                {
                    DLog(@"跑出去");
                    return ;
                }
                NSArray *frames = [wearSelf.decoder decodeFrames];
                if (frames ==nil)
                {
                    //发生错误;
                    break;
                }else if(frames.count)
                {
                    good = [wearSelf addFrames:frames];
                }
                frames = nil;
            }
        }
        if (!wearSelf.playing)
        {
            DLog(@"已经中断");
        }
        wearSelf.decoding = NO;
    });
}
#pragma mark 添加frame
- (BOOL) addFrames: (NSArray *)frames
{
    @synchronized(_videoFrames)
    {
        for (KxMovieFrame *frame in frames)
        {
            if (frame.type == KxMovieFrameTypeVideo)
            {
                [_videoFrames addObject:frame];
                _bufferedDuration += frame.duration;
            }
        }
    }
    return self.playing && _bufferedDuration < kMAXBUFFEREDDURATION_IPC;
}
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
#pragma mark 重力处理
- (BOOL)shouldAutorotate
{
    return NO;
}
-(NSUInteger)supportedInterfaceOrientations
{
    //UIInterfaceOrientationMaskPortrait
    return UIInterfaceOrientationMaskLandscapeRight;
}

-(CGAffineTransform)transformView
{
    if(!bScreen)
    {
        return CGAffineTransformMakeRotation(M_PI/2);
    }
    else
    {
        return CGAffineTransformIdentity;
    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
//    [self setNewVerticalFrame];
}

-(void)playWithAction:(UIButton*)sender
{
    if (sender.selected)
    {
        [self stopVideo];
        __weak UIButton *stopBtn = sender;
       dispatch_async(dispatch_get_main_queue(), ^{
            stopBtn.selected = NO;
        });
    }
    else
    {
        [self playVideo];
        __weak UIButton *stopBtn = sender;
        dispatch_async(dispatch_get_main_queue(), ^{
            stopBtn.selected = YES;
            stopBtn.enabled = NO;
        });
        
    }
}
#pragma mark 连接视频  起点
-(void)playVideo
{
    if (nPlayStatus)
    {
        return ;
    }
    __weak PlayP2PViewController *__weakSelf = self;
    //bScreen)//bScreen no 竖屏   yes 横屏
        if (IOS_SYSTEM_8)
        {
            dispatch_async(dispatch_get_main_queue(),
            ^{
               [ProgressHUD show:XCLocalized(@"loading") viewInfo:__weakSelf.view];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ProgressHUD showPlayRight:XCLocalized(@"loading") viewInfo:__weakSelf.view];
            });
        }
    
    
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__weakSelf decoderInfo];
        
    });
    nPlayStatus = 1;
}
#pragma mark 停止视频
-(void)stopVideo
{
    _playing = NO;
    _hiddenHUD = NO;
    [_decoder releaseDecode];
    __weak PlayP2PViewController *_weakSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [_weakSelf setPlayMode:NO];
        [_weakSelf.glView removeFromSuperview];
        _weakSelf.glView= nil;
    });
    if(bRecord)
    {
        [_progressLabel removeFromSuperview];
        bRecord = !bRecord;
        _startDuration = 0;
        _btnRecord.selected = NO;
    }
    [self showToolBar];
    @synchronized(_videoFrames)
    {
        [_videoFrames removeAllObjects];
    }
    _imgView = nil;
    __weak UIButton *btn = btnSwitch;
    dispatch_async(dispatch_get_main_queue(),
    ^{
       [_weakSelf.btnPlay setSelected:NO];
        [_weakSelf.btnPlay setEnabled:YES];
        [_weakSelf.btnBD setEnabled:NO];
        btn.selected = NO;
    });
    nPlayStatus = 0;
    [self.view addGestureRecognizer:_doubleRecognizer];
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    [NSThread sleepForTimeInterval:0.5f];
    _decoder = nil;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}
#pragma mark 码流切换
/*
    码流切换:
    默认是2:子码流   流畅
    1:主码流    高清
*/
-(void)switchVideoCode:(int)nCode
{
    _playing = NO;
    _decoding = NO;
    
   //默认bScreen横屏幕
    __weak PlayP2PViewController *__weakSelf = self;
    if (IOS_SYSTEM_8)
    {
        dispatch_async(dispatch_get_main_queue(),
        ^{
             [ProgressHUD show:XCLocalized(@"videoSwitch") viewInfo:__weakSelf.view];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ProgressHUD showPlayRight:XCLocalized(@"videoSwitch") viewInfo:__weakSelf.view];
        });
    }
    __block int __nCode = nCode;
    /*
        切换分为两种情况
        1.如果是P2P,使用切换
        2.如果是转发，停止视频播放，然后重新连接视频
        先获取码流信息，在decoder类中加入信息
    */
    if ([_decoder getRealType]==1)
    {
        //P2P方式  直接转换
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0),
        ^{
               if (__weakSelf.decoder)
               {
                   [__weakSelf.decoder switchP2PCode:__nCode];
               }
               while (!__weakSelf.decoder.nSwitchcode)
               {
                   [NSThread sleepForTimeInterval:0.1f];
               }
               __weakSelf.nCodeType = __nCode;
               [__weakSelf play];
               @synchronized(__weakSelf.videoFrames)
               {
                   [__weakSelf.videoFrames removeAllObjects];
               }
        });
    }
    else
    {
        if (bRecord)
        {
            [self recordVideo];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartTran) name:NS_SWITCH_TRAN_OPEN_VC object:nil];
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__weakSelf stopVideo];
        });
        _nCodeType = nCode;
    }
}
-(void)restartTran
{
    __weak PlayP2PViewController *__weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__weakSelf decoderTran];
    });
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NS_SWITCH_TRAN_OPEN_VC object:nil];
}



#pragma mark 抓拍
-(void)shotoPic:(UIButton*)btnSender
{
    //YUV 方式抓拍  captureToPhotoAlbum:(UIView *)_glView name:(NSString*)devName;
    btnSender.enabled = NO;
    UIImage *image = [_decoder capturePhoto];
    BOOL bFlag = [CaptureService captureToPhotoYUV:image name:_strName];//width:_decoder.frameWidth height:_decoder.frameHeight];
    if (bFlag)
    {
        __weak PlayP2PViewController *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view makeToast:XCLocalized(@"captureS") duration:1.0 position:@"center"];
        });
    }else
    {
        if (bFlag) {
            __weak PlayP2PViewController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [weakSelf.view makeToast:XCLocalized(@"captureF") duration:1.0 position:@"center"];
            });
        }
    }
    image = nil;
    [self performSelector:@selector(snaptBtnEnYes) withObject:nil afterDelay:1.5];
}
-(void)snaptBtnEnYes
{
    __weak UIButton *btnSender =(UIButton*)[_downHUD viewWithTag:1003];
    dispatch_async(dispatch_get_main_queue(),
    ^{
        btnSender.enabled = YES;
    });
}


-(void)recordVideo
{
    if(bRecord)
    {
        bRecord = NO;
        [self.view makeToast:XCLocalized(@"stopRecord") duration:1.0 position:@"center"];
        [_decoder recordStop];
        __weak UILabel *lblProgress = _progressLabel;
        dispatch_async(dispatch_get_main_queue(), ^{
            lblProgress.hidden = YES;
        });
        _startDuration = 0;
    }
    else
    {
        _btnRecord.enabled = NO;
        UIImage *image = [_decoder capturePhoto];
        DLog(@"image:%@",image);
        [self.view makeToast:XCLocalized(@"startRecord") duration:1.0 position:@"center"];
        NSString *strPath = [CaptureService captrueRecordYUV:image];
        [_decoder recordStart:strPath name:_strName];
        _progressLabel.hidden = NO;
        _startDuration = _movieDuration;
        bRecord = !bRecord;
        image = nil;
        [self performSelector:@selector(recordBtnEnYes) withObject:nil afterDelay:1.5];
    }
    _btnRecord.selected = bRecord;
}
-(void)recordBtnEnYes
{
    __weak UIButton *btnSender = _btnRecord;
    dispatch_async(dispatch_get_main_queue(), ^{
        btnSender.enabled = YES;
    });
}

#pragma mark 新横屏
-(void)setNewVerticalFrame
{

    if (IOS_SYSTEM_8)
    {
        fWidth = kScreenWidth;
        fHeight = kScreenHeight;
    }
    else
    {
        fWidth = kScreenSourchHeight;
        fHeight = kScreenSourchWidth;
    }
    _topHUD.frame = Rect(0, 0, fWidth, 49);
    
    topViewBg.frame=_topHUD.bounds;
    
    [_topHUD insertSubview:topViewBg atIndex:0];
    
    [_lblName setTextColor:[UIColor whiteColor]];
    _lblName.frame = Rect(50, 13, fWidth/*width*/ - 160, 20);
    _downHUD.frame = Rect(0, fHeight-50,fWidth , 50);
    [_lblName setTextAlignment:NSTextAlignmentLeft];
    
    [_progressLabel removeFromSuperview];
    [_progressLabel setFrame:Rect(10,15, 60, 20)];
    
    [_downHUD addSubview:_progressLabel];
    
    [_downHUD insertSubview:downViewBg atIndex:0];
    downViewBg.frame = _downHUD.bounds;
    
    //横屏的时候修改变更内容
    [_downHUD viewWithTag:1001].frame = Rect(fWidth-60*3,  1 , 60, 48);
    [_downHUD viewWithTag:1003].frame = Rect(fWidth-60*2, 1 , 60, 48);
    [_downHUD viewWithTag:1004].frame = Rect(fWidth-60, 1 , 60, 48);

    [_btnBD removeFromSuperview];
    [_btnHD removeFromSuperview];
    
    [_topHUD addSubview:_btnHD];
    [_topHUD addSubview:_btnBD];
    [_topHUD addSubview:btnPtz];
    
    _btnBD.frame = Rect(fWidth-60*3, 0, 60,48);
    _btnHD.frame = Rect(fWidth-60*2, 0, 60,48);
    
    btnPtz.frame = Rect(fWidth-60, 0, 60, 48);
    
    [btnPtz addTarget:self action:@selector(showPtzView) forControlEvents:UIControlEventTouchUpInside];
    
    [_btnBD setImage:[UIImage imageNamed:@"full_bd"] forState:UIControlStateNormal];
    [_btnHD setImage:[UIImage imageNamed:@"full_hd"] forState:UIControlStateNormal];
    
    _view_Ptz.frame = Rect(fWidth-164,fHeight/2-57, 164, 114);

}

/**
 *  云台操控信息
 */
-(void)showPtzView
{
    _view_Ptz.hidden = !_view_Ptz.hidden;
}


#pragma mark 竖屏,已弃用
-(void)setHorizontalFrame
{
    _downHUD.frame = Rect(0, kScreenHeight-50,kScreenWidth, 50);
    [_progressLabel removeFromSuperview];
    [_topHUD addSubview:_progressLabel];
    _progressLabel.frame = Rect(kScreenWidth-80, 11, 60, 20);
    [_lblName setTextColor:[UIColor blackColor]];
    _lblName.frame = Rect(80,15,kScreenWidth-160,20);

    _view_Ptz.hidden = YES;
    [self frameView].frame = frameCenter;
    [_downHUD viewWithTag:1001].frame = Rect(kScreenWidth/2-150, 2 , 60, 48);
    [_downHUD viewWithTag:1003].frame = Rect(kScreenWidth/2-90, 2 , 60, 48);
    [_downHUD viewWithTag:1004].frame = Rect(kScreenWidth/2-30, 2 , 60, 48);
    _btnBD.frame = Rect(kScreenWidth/2+30, 2, 60, 48);
    _btnHD.frame = Rect(kScreenWidth/2+90, 2, 60, 48);
    
    [(UIButton*)[_downHUD viewWithTag:1001] setImage:[UIImage imageNamed:@"realplay"] forState:UIControlStateNormal];
    [(UIButton*)[_downHUD viewWithTag:1001] setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateSelected];
    [(UIButton*)[_downHUD viewWithTag:1003] setImage:[UIImage imageNamed:@"shotopic"] forState:UIControlStateNormal];
    [(UIButton*)[_downHUD viewWithTag:1004] setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    [_btnBD setImage:[UIImage imageNamed:@"play_bd"] forState:UIControlStateNormal];
    [_btnHD setImage:[UIImage imageNamed:@"play_hd"] forState:UIControlStateNormal];
    
    _hiddenHUD = NO;
    [self showToolBar];
    
    [topViewBg removeFromSuperview];
    [downViewBg removeFromSuperview];
}

-(UIView*)frameView
{
    return _glView ? _glView : _imgView;
}

#pragma mark 视频播放模式,设置播放按钮
-(void)setPlayMode:(BOOL)bPlayMode
{
    if ([UserInfo sharedUserInfo].bGuess)
    {
        ((UIButton*)[_downHUD viewWithTag:1003]).enabled = NO;
        ((UIButton*)[_downHUD viewWithTag:1004]).enabled = NO;
        _btnHD.enabled = NO;
        _btnBD.enabled = NO;
        
    }
    else
    {
        ((UIButton*)[_downHUD viewWithTag:1003]).enabled = bPlayMode;
        ((UIButton*)[_downHUD viewWithTag:1004]).enabled = bPlayMode;
        if(_playing)
        {
            if (_nCodeType==1)//高清
            {
                _btnBD.enabled = YES;//1005  bd的tag
                _btnHD.enabled = NO;//1006   hd的tag
            }
            else//标清
            {
                _btnBD.enabled = NO;
                _btnHD.enabled = YES;
            }
        }
        else
        {
            _btnBD.enabled = NO;
            _btnHD.enabled = NO;
        }
    }
}


-(void)testFunction
{
    DLog(@"test function");
}

/**
 *  云台发送指令
 *
 *  @param ptzCmd 云台动作信息
 */
-(void)ptzView:(int)ptzCmd
{
    if(_decoder)
    {
        [_decoder ptz_control:ptzCmd];
    }
}
@end
