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
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define MAX_FRAME  6
#define MIN_FRAME  1

#define VIDEO_LOW  NSLocalizedString(@"videoLow", nil)
#define VIDEO_HIGH  NSLocalizedString(@"videoHight", nil)


@interface PlayP2PViewController()
{
    dispatch_queue_t _dispatchQueue;
    BOOL                bFirst;
    UIActivityIndicatorView  *viewActivity;
    
    UIView              *_topHUD;
    UIView              *_downHUD;
    UIToolbar           *_topBar;
    UIButton            *_doneButton;
    UITapGestureRecognizer *_doubleRecognizer;
    UITapGestureRecognizer *_tapGestureRecognizer;
    BOOL    _hiddenHUD;
    
    CGFloat _bufferedDuration;
    CGFloat _minBufferedDuration;
    CGFloat _maxBufferedDuration;
    
    NSTimeInterval      _tickCorrectionTime;
    NSTimeInterval      _tickCorrectionPosition;
    NSUInteger    _tickCounter;
    
    UILabel *_progressLabel;
    
    UIButton *_recordBtn ;
    
    int nPlayStatus;
    NSUInteger _nFormat;

    CGRect frameCenter;
    BOOL bIsFull;
    BOOL bRecord;
    BOOL bStart;
    BOOL _buffered;
    int nWidth ;
    int nHeight ;
    
    UILabel *_lblName;
    CGFloat _movieDuration;
    CGFloat _startDuration;
    UIButton *btnSwitch;
}
@property (nonatomic) BOOL decoding;
@property (nonatomic,strong) XCDecoder *decoder;
@property (nonatomic,strong) NSString *strNO;
@property (nonatomic,strong) UILabel *lblPlayer;
@property (readwrite) BOOL playing;
@property (nonatomic,strong) NSString *strName;
@property (nonatomic,strong) KxMovieGLView *glView;
@property (nonatomic,strong) UIView *switchView;
@property (nonatomic,strong) NSMutableArray      *videoFrames;;
@end

@implementation PlayP2PViewController

-(id)initWithNO:(NSString*)nsNO;
{
    self = [super init];
    if (self) {
        self.strNO = [nsNO copy];
    }
    return self;
}
-(id)initWithNO:(NSString*)nsNO name:(NSString*)strName format:(NSUInteger)nFormat
{
    self = [super init];
    if (self) {
        self.strNO = [nsNO copy];
        _nFormat = nFormat;
        _strName = [strName copy];
    }
    return self;
}
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {

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
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1; // 单击
    _doubleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleRecognizer.numberOfTapsRequired = 2; // 双击
    [_tapGestureRecognizer requireGestureRecognizerToFail:_doubleRecognizer];
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    [self.view addGestureRecognizer:_doubleRecognizer];
    [self.view setUserInteractionEnabled:YES];
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

- (void) setupUserInteraction
{
//    _glView.userInteractionEnabled = YES;
//    [_glView addGestureRecognizer:_tapGestureRecognizer];
//    [_glView addGestureRecognizer:_doubleRecognizer];
//    [self.view setUserInteractionEnabled:YES];
//    [self.view addGestureRecognizer:_tapGestureRecognizer];
//    [self.view addGestureRecognizer:_doubleRecognizer];

}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connect_p2p_fail:) name:NSCONNECT_P2P_FAIL_VC object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enter_background) name:NS_APPLITION_ENTER_BACK object:nil];
}
-(void)enter_background
{
    [_decoder destorySDK];
    [self stopVideo];
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [ProgressHUD dismiss];
}

-(void)handleTap:(UITapGestureRecognizer*)tapGesture
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
            bIsFull = !bIsFull;
            if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
            {
                [self setHorizontalFrame];
            }
            else
            {
                [self setVerticalFrame];
            }
        }
    }
}
- (void) showHUD: (BOOL) show
{
    if (!_switchView.hidden) {
        _switchView.hidden = YES;
        return;
    }
    _hiddenHUD = !show;

    [self showToolBar];
}

-(void)showToolBar
{
    _topHUD.alpha = _hiddenHUD ? 0 :1;
    _downHUD.alpha = _hiddenHUD ? 0 : 1;
}
-(void)initToolBar
{
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenWidth,44)];
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topHUD];
    _topHUD.alpha = 1;
    [_topHUD setBackgroundColor:[UIColor clearColor]];
    
    UIView *alphView = [[UIView alloc] initWithFrame:_topHUD.bounds];
    alphView.tag = 1010;
    [alphView setBackgroundColor:RGB(255,255,255)];
    [alphView setAlpha:0.5f];
    [_topHUD addSubview:alphView];
    [_topHUD setUserInteractionEnabled:YES];
    alphView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, 43, kScreenWidth, 1)];
    [lineView setBackgroundColor:[UIColor grayColor]];
    [_topHUD addSubview:lineView];
    lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,20,kScreenWidth-60,15)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:_strName];
    [_lblName setFont:[UIFont systemFontOfSize:15.0f]];
    [_lblName setTextColor:[UIColor blackColor]];
    [_topHUD addSubview:_lblName];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(5,0,40,40);
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch:)
          forControlEvents:UIControlEventTouchUpInside];
    [_topHUD addSubview:_doneButton];
    
    _progressLabel = [[UILabel alloc] initWithFrame:Rect(0, 0, 60, 20)];
    [_progressLabel setTextAlignment:NSTextAlignmentCenter];
    [_progressLabel setTextColor:[UIColor redColor]];
    [_progressLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [_progressLabel setBackgroundColor:[UIColor blackColor]];
    [_progressLabel setAlpha:0.6f];
    
    _downHUD = [[UIView alloc] initWithFrame:Rect(0, kScreenHeight-50+HEIGHT_MENU_VIEW(20, 0),kScreenWidth, 50)];
    _downHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_downHUD];
    _downHUD.alpha = 1;
    [_downHUD setBackgroundColor:[UIColor clearColor]];
    
    UIView *alphDownView = [[UIView alloc] initWithFrame:_downHUD.bounds];
    alphDownView.tag = 1010;
    [alphDownView setBackgroundColor:RGB(255,255,255)];
    [alphDownView setAlpha:0.5f];
    [_downHUD addSubview:alphDownView];
    alphDownView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIView *lineViewDown = [[UIView alloc] initWithFrame:Rect(0, 1, kScreenWidth, 1)];
    [lineViewDown setBackgroundColor:[UIColor grayColor]];
    [_downHUD addSubview:lineViewDown];
    lineViewDown.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [playBtn setImage:[UIImage imageNamed:@"realplay"] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    playBtn.tag = 1001;
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopBtn setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    [stopBtn addTarget:self action:@selector(stopVideo) forControlEvents:UIControlEventTouchUpInside];
    stopBtn.tag = 1002;
    UIButton *shotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [shotoBtn setImage:[UIImage imageNamed:@"shotopic"] forState:UIControlStateNormal];
    [shotoBtn addTarget:self action:@selector(shotoPic) forControlEvents:UIControlEventTouchUpInside];
    shotoBtn.tag = 1003;
    _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_recordBtn setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    [_recordBtn addTarget:self action:@selector(recordVideo) forControlEvents:UIControlEventTouchUpInside];
    [_recordBtn setImage:[UIImage imageNamed:@"record_sel"] forState:UIControlStateSelected];
    [_recordBtn setImage:[UIImage imageNamed:@"record_select"] forState:UIControlStateHighlighted];
    _recordBtn.tag = 1004;
    
    btnSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSwitch setTitle:VIDEO_LOW forState:UIControlStateNormal];
    [btnSwitch setBackgroundColor:[UIColor grayColor]];
    [btnSwitch setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnSwitch addTarget:self action:@selector(viewSwitchView:) forControlEvents:UIControlEventTouchUpInside];
    btnSwitch.tag = 1005;
    [_downHUD addSubview:btnSwitch];

     
    [_recordBtn setEnabled:NO];
    [playBtn setEnabled:NO];
    [shotoBtn setEnabled:NO];
    [_recordBtn  setEnabled:NO];
    [stopBtn setEnabled:NO];
    
    [_downHUD addSubview:playBtn];
    [_downHUD addSubview:stopBtn];
    [_downHUD addSubview:shotoBtn];
    [_downHUD addSubview:_recordBtn];
    
//  shotoBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
//    
//    stopBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
//    _recordBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
//    playBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
//    btnSwitch.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    _switchView = [[UIView alloc] initWithFrame:Rect(0, kScreenHeight-100, 45, 60)];
    [_switchView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:_switchView];
    UIButton *btnCode1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCode1 setTitle:VIDEO_HIGH forState:UIControlStateNormal];
    [btnCode1 setBackgroundColor:[UIColor grayColor]];
    [btnCode1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnCode1 addTarget:self action:@selector(switchVideoCodeInfo:) forControlEvents:UIControlEventTouchUpInside];
    [_switchView addSubview:btnCode1];
    [btnCode1 setFrame:Rect(0, 0, 45, 30)];
    
    UIButton *btnCode2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCode2 setTitle:VIDEO_LOW forState:UIControlStateNormal];
    [btnCode2 setBackgroundColor:[UIColor grayColor]];
    [btnCode2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnCode2 addTarget:self action:@selector(switchVideoCodeInfo:) forControlEvents:UIControlEventTouchUpInside];
    [_switchView addSubview:btnCode2];
    [btnCode2 setFrame:Rect(0, 31, 45, 30)];
    [_switchView setHidden:YES];
}
#pragma mark - actions
- (void)doneDidTouch: (id) sender
{
    [self stopVideo];
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    }];
}
-(void)connect_p2p_fail:(NSNotification*)notify
{
    
    [self stopVideo];
    
    NSString *strInfo = [notify object];
    __weak NSString *__strInfo = strInfo;
    __weak PlayP2PViewController *__weakSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [ProgressHUD dismiss];
        [__weakSelf.view makeToast:__strInfo];
    });
    
}


-(void)decoderInfo
{
    _playing = YES;
    _decoder = [[XCDecoder alloc] initWithNO:_strNO format:_nFormat];
    while(_decoder.frameWidth==0)
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
-(void)playMovie
{
    if (self.playing)
    {
        NSMutableArray *array = [_decoder getVideoArray];
        DLog(@"array:%d",array.count);
        KxVideoFrame *frame ;
        @synchronized(array)
        {
            if (array.count > 0) {
                frame = array[0];
                [array removeObjectAtIndex:0];
            }
        }
        if (frame)
        {
            DLog(@"贴图");
            [_glView render:frame];
            [_decoder clearDuration:frame.duration];
            frame = nil;
        }
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0/_decoder.fps * NSEC_PER_SEC);
    __weak PlayP2PViewController *weakSelf = self;
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf playMovie];
    });
}





-(void)initGlView
{
    float height = _decoder.frameHeight/(_decoder.frameWidth/320.0f);
    frameCenter = Rect(0, kScreenHeight/2-height/2,320,height);
    _glView = [[KxMovieGLView alloc] initWithFrame:frameCenter decoder:_decoder];
    _glView.contentMode = UIViewContentModeScaleAspectFit;//UIViewContentModeScaleAspectFill;UIViewContentModeScaleAspectFit
    _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:_glView];
    [self setupUserInteraction];
    __weak PlayP2PViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__self setPlayMode:YES];
    });
    
    
}

- (void) play
{
    if (_playing) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{[ProgressHUD dismiss];});
    _decoding = NO;
    _tickCounter = 0;
    _tickCorrectionTime = 0;
    _playing = YES;    
    [self asyncDecodeFrames];
    [viewActivity stopAnimating];
    __weak PlayP2PViewController *wearSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (1.0/100) * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
    {
        if(wearSelf.playing)
        {
            [wearSelf tick];
        }
    });
}
- (void) tick
{
    if (_buffered && (_buffered>_minBufferedDuration || _decoder.isEOF))
    {
        _tickCorrectionTime = 0;
        _buffered = NO;
    }
    CGFloat interval = 0;
    if(!_buffered)
    {
        interval = [self presentFrame];
    }
    if (self.playing) {
        const NSUInteger leftFrames = _videoFrames.count;
        if (!leftFrames || _bufferedDuration < _minBufferedDuration)
        {
            [self asyncDecodeFrames];
        }
        if (_decoder.isEOF && _bufferedDuration == 0)
        {
            return ;
        }
        __weak PlayP2PViewController *wearSelf = self;
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.01);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [wearSelf tick];
        });
    }
    if ((_tickCounter++ % 3) == 0)
    {
        [self updateHUD];
    }
}
-(NSString*)formatTimeInterval:(CGFloat) seconds
{
    seconds = MAX(0, seconds);
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    s = s % 60;
    m = m % 60;
    return [NSString stringWithFormat:@"%d:%0.2d:%0.2d",h,m,s];
}
-(void)updateHUD
{
    if(!bRecord)
    {
        return;
    }
    const CGFloat position = _movieDuration-_startDuration;// -_decoder.startTime;
    _progressLabel.text = [self formatTimeInterval:position];
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
    
    if (correction > 1.f || correction < -1.f) {
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
        [_glView render:frame];
        _movieDuration = frame.position;
        interval = frame.duration;
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
- (void) asyncDecodeFrames
{
    if (self.decoding)
        return;
    __weak PlayP2PViewController *wearSelf = self;
    self.decoding = YES;
    dispatch_async(_dispatchQueue, ^{
        BOOL good = YES;
        while (good) {
            good = NO;
            @autoreleasepool
            {
                if (!wearSelf.playing)
                {
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
    return self.playing && _bufferedDuration < _maxBufferedDuration;
}
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
-(BOOL)shouldAutorotate
{
    if (IOS_SYSTEM_8) {
        return NO;
    }
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
-(void)dealloc
{
    [_videoFrames removeAllObjects];
    [_tapGestureRecognizer removeTarget:self action:@selector(handleTap:)];
    [_doubleRecognizer removeTarget:self action:@selector(handleTap:)];
    [_glView removeFromSuperview];
    [_downHUD removeFromSuperview];
    [_topHUD removeFromSuperview];
    [_lblName removeFromSuperview];
    _decoder = nil;
    _glView = nil;
    _dispatchQueue = nil;
    _doneButton = nil;
    _topHUD = nil;
    _topBar = nil;
    
}
-(void)viewWillLayoutSubviews
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        //翻转为竖屏时
        [self setHorizontalFrame];
    }else if (interfaceOrientation==UIDeviceOrientationLandscapeLeft || interfaceOrientation ==UIDeviceOrientationLandscapeRight) {
        //翻转为横屏时
        [self setVerticalFrame];
    }
}

#pragma mark 连接视频  起点
-(void)playVideo
{
    if (nPlayStatus)
    {
        return ;
    }
    [ProgressHUD show:NSLocalizedString(@"loading", "loading")];
    __weak PlayP2PViewController *__weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [__weakSelf decoderInfo];
    });
    nPlayStatus = 1;
}
#pragma mark 停止视频
-(void)stopVideo
{
    
    nPlayStatus = 0;
    _hiddenHUD = NO;
    [_decoder releaseDecode];
    [_glView removeFromSuperview];
    if(bRecord)
    {
        [_progressLabel removeFromSuperview];
        bRecord = !bRecord;
        _startDuration = 0;
        _recordBtn.selected = NO;
    }
    [self showToolBar];
    _playing = NO;
    @synchronized(_videoFrames)
    {
        [_videoFrames removeAllObjects];
    }
    _decoder = nil;
    _glView = nil;
    [self setPlayMode:NO];
    UIButton *btn = (UIButton*)[_downHUD viewWithTag:1001];
    __weak UIButton *btnWeak = btn;
    dispatch_async(dispatch_get_main_queue(), ^{
        [btnWeak setEnabled:YES];
    });
    __weak PlayP2PViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
       [__self setPlayMode:NO];
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [ProgressHUD show:NSLocalizedString(@"videoSwitch", nil)];
    });
    if (_decoder)
    {
        _decoder.nSwitchcode = NO;
        
        [_decoder switchP2PCode:nCode];
    }
    __weak PlayP2PViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        while (!weakSelf.decoder.nSwitchcode)
        {
            [NSThread sleepForTimeInterval:0.1f];
        }
        [weakSelf play];
        @synchronized(weakSelf.videoFrames)
        {
            [weakSelf.videoFrames removeAllObjects];
        }
    });
    [_switchView setHidden:YES];
}

-(void)viewSwitchView:(id)sender
{
    [_switchView setHidden:NO];
    
}
-(void)switchVideoCodeInfo:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    int nType = 0;
    if([btn.titleLabel.text isEqualToString:VIDEO_HIGH])
    {
        [btnSwitch setTitle:VIDEO_HIGH forState:UIControlStateNormal];
        nType= 1;
    }
    else
    {
        [btnSwitch setTitle:VIDEO_LOW forState:UIControlStateNormal];
        nType = 2;
    }
    [self switchVideoCode:nType];
}

#pragma mark 抓拍
-(void)shotoPic
{
    BOOL bFlag = [CaptureService captureToPhotoAlbum:_glView];
    if (bFlag) {
        __weak PlayP2PViewController *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view makeToast:@"抓拍成功"];
        });
    }else
    {
        if (bFlag) {
            __weak PlayP2PViewController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view makeToast:@"抓拍失败"];
            });
        }
    }
}

-(void)recordVideo
{
    if(bRecord)
    {
        [self.view makeToast:@"录像停止" duration:1.0 position:@"center"];
        [_decoder recordStop];
        [_progressLabel removeFromSuperview];
        bRecord = !bRecord;
        _startDuration = 0;
    }
    else
    {
        [self.view makeToast:@"录像开始" duration:1.0 position:@"center"];
        [_decoder recordStart];
        
        [_topHUD addSubview:_progressLabel];
        _startDuration = _movieDuration;
        bRecord = !bRecord;
    }

    _recordBtn.selected = bRecord;
}




#pragma mark 横屏
-(void)setVerticalFrame
{
    if(IOS_SYSTEM_8)
    {
        _lblName.frame = Rect(80,10,kScreenWidth-160,15);
        _downHUD.frame = CGRectMake(0, kScreenHeight-40, kScreenWidth, 44);
        _progressLabel.frame = Rect(kScreenWidth-80, 10, 60, 20);
        _glView.frame = self.view.frame;
        _glView.contentMode = bIsFull ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
    }
    else
    {
  //      _topHUD.frame = Rect(0, 0, kScreenHeight, 44);
        _lblName.frame = Rect(80, 10, kScreenHeight - 160, 15);
        _progressLabel.frame = Rect(kScreenHeight-80, 10, 60, 20);
        _downHUD.frame = Rect(0, kScreenWidth-50, kScreenHeight, 50);
        _glView.frame = Rect(0, 0,kScreenHeight, kScreenWidth);
        _glView.contentMode = bIsFull ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
        
        
        [_downHUD viewWithTag:1001].frame = Rect(kScreenHeight/2-122.5, 2, 45, 45);
        [_downHUD viewWithTag:1002].frame = Rect(kScreenHeight/2-72.5, 2, 45, 45);
        [_downHUD viewWithTag:1003].frame = Rect(kScreenHeight/2-22.5, 2, 45, 45);
        [_downHUD viewWithTag:1004].frame = Rect(kScreenHeight/2+22.5,2, 45, 45);
        [_downHUD viewWithTag:1005].frame = Rect(kScreenHeight/2+72.5, 10, 45, 30);
        [_switchView setFrame:Rect(btnSwitch.frame.origin.x, kScreenWidth-108, 45,60)];
        
    }
}

#pragma mark 竖屏
-(void)setHorizontalFrame
{
    if (IOS_SYSTEM_8)
    {
        _progressLabel.frame = Rect(kScreenWidth-80, 10, 60, 20);
        _lblName.frame = Rect(80,10,kScreenWidth-160,15);
        _downHUD.frame = Rect(0, kScreenHeight-40, kScreenWidth, 40);
        _glView.frame = bIsFull ? self.view.frame : frameCenter;
        _glView.contentMode = bIsFull ? UIViewContentModeScaleAspectFill :UIViewContentModeScaleAspectFit ;
    }else
    {

        _progressLabel.frame = Rect(kScreenWidth-80, 10, 60, 20);
        _lblName.frame = Rect(80,10,kScreenWidth-160,15);
        _downHUD.frame = Rect(0, kScreenHeight-50,kScreenWidth, 50);
        _glView.frame = bIsFull ? self.view.frame : frameCenter;
        _glView.contentMode = bIsFull ? UIViewContentModeScaleAspectFill:UIViewContentModeScaleAspectFit ;
        
        [_downHUD viewWithTag:1001].frame = Rect(30, 2, 45, 45);
        [_downHUD viewWithTag:1002].frame = Rect(80, 2, 45, 45);
        [_downHUD viewWithTag:1003].frame = Rect(130, 2, 45, 45);
        [_downHUD viewWithTag:1004].frame = Rect(180,2, 45, 45);
        [_downHUD viewWithTag:1005].frame = Rect(230, 10, 45, 30);
        [_switchView setFrame:Rect(btnSwitch.frame.origin.x, kScreenHeight-108,45, 60)];
    }
}

#pragma mark 视频播放模式
-(void)setPlayMode:(BOOL)bPlayMode
{
    for (UIButton *btn in _downHUD.subviews)
    {
        if (btn.tag == 1001)
        {
            [btn setEnabled:!bPlayMode];
        }else
        {
            [btn setEnabled:bPlayMode];
        }
    }
}
//-(void)transformViewController
//{
//    UIInterfaceOrientation interface = [UIApplication sharedApplication].statusBarOrientation;
//    self.view.transform = CGAffineTransformMakeRotation(M_PI/2);
//    self.view.bounds = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
//}


@end
