//
//  ViewController.m
//  kxmovieapp
//
//  Created by Kolyvan on 11.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import <Foundation/Foundation.h>
#import "PlayNetViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "XCDecoder.h"
#import "KxMovieGLView.h"
#import "KxAudioManager.h"
#import "RecordModel.h"
#import "Toast+UIView.h"
#import "XCNotification.h"
#import "UtilsMacro.h"
#import "CustomNaviBarView.h"

NSString * const KxMovieParameterMinBufferedDuration = @"KxMovieParameterMinBufferedDuration";
NSString * const KxMovieParameterMaxBufferedDuration = @"KxMovieParameterMaxBufferedDuration";
NSString * const KxMovieParameterDisableDeinterlacing = @"KxMovieParameterDisableDeinterlacing";

////////////////////////////////////////////////////////////////////////////////

static NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    seconds = MAX(0, seconds);
    
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    
    s = s % 60;
    m = m % 60;
    
    return [NSString stringWithFormat:@"%@%d:%0.2d:%0.2d", isLeft ? @"-" : @"", h,m,s];
}

////////////////////////////////////////////////////////////////////////////////

@interface HudView : UIView
@end

@implementation HudView

- (void)layoutSubviews
{
    NSArray * layers = self.layer.sublayers;
    if (layers.count > 0) {
        CALayer *layer = layers[0];
        layer.frame = self.bounds;
    }
}
@end

////////////////////////////////////////////////////////////////////////////////

enum {
    
    KxMovieInfoSectionGeneral,
    KxMovieInfoSectionVideo,
    KxMovieInfoSectionAudio,
    KxMovieInfoSectionSubtitles,
    KxMovieInfoSectionMetadata,
    KxMovieInfoSectionCount,
};

enum {
    
    KxMovieInfoGeneralFormat,
    KxMovieInfoGeneralBitrate,
    KxMovieInfoGeneralCount,
};

////////////////////////////////////////////////////////////////////////////////

static NSMutableDictionary * gHistory;

#define LOCAL_MIN_BUFFERED_DURATION   0.2
#define LOCAL_MAX_BUFFERED_DURATION   0.4
#define NETWORK_MIN_BUFFERED_DURATION 2.0
#define NETWORK_MAX_BUFFERED_DURATION 4.0

@interface PlayNetViewController ()
{
    
    
    BOOL _interrupted;
    BOOL _hiddenHUD;
    BOOL _buffered;
    BOOL _savedIdleTimer;
    BOOL   bIsFull;
    BOOL _disableUpdateHUD;
    KxMovieGLView       *_glView;
    NSMutableArray      *_videoFrames;
    dispatch_queue_t    _dispatchQueue;
    

    UITapGestureRecognizer *_tapGestureRecognizer;
    UITapGestureRecognizer *_doubleRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;
    
    CGFloat _bufferedDuration;
    CGFloat _minBufferedDuration;
    CGFloat _maxBufferedDuration;
    CGFloat _moviePosition;
    NSTimeInterval  _tickCorrectionTime;
    NSTimeInterval  _tickCorrectionPosition;
    NSUInteger  _tickCounter;
    CGRect frameCenter;
    
    UISlider *_progressSlider;
    UIButton *_doneButton;
    UIView *_topHUD;
    UIView *_downHUD;
    
    UILabel *_progressLabel;
    UILabel *_leftLabel;
    UILabel *_lblName;
    
    UIButton *_playBtn;
    
}

@property (readwrite) BOOL playing;
@property (readwrite) BOOL decoding;
@property (nonatomic,strong) NSString *strPath;
@property (nonatomic,strong) XCDecoder *decoder;
@property (nonatomic,strong) RecordModel *record;
@end

@implementation PlayNetViewController

+ (void)initialize
{
    if (!gHistory)
        gHistory = [NSMutableDictionary dictionary];
}

+ (id) initWithContentPath: (RecordModel *) record
                parameters: (NSDictionary *) parameters;
{
    id<KxAudioManager> audioManager = [KxAudioManager audioManager];
    [audioManager activateAudioSession];
    return [[PlayNetViewController alloc] initWithContentPath: record parameters: parameters];
}

- (id) initWithContentPath: (RecordModel *) record
                parameters: (NSDictionary *) parameters;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _moviePosition = 0;
        self.wantsFullScreenLayout = YES;
        _record = record;
    }
    return self;
}



- (void) dealloc
{
    if (_decoder) {
        [_decoder releaseDecode];
        _decoder = nil;
    }
    for (UIView *view in _topHUD.subviews) {
        [view removeFromSuperview];
    }
    for (UIView *view in _downHUD.subviews) {
        [view removeFromSuperview];
    }
    if (_glView) {
        [_glView removeFromSuperview];
        _glView = nil;
    }
    _strPath = nil;
    _record = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%@ dealloc", self);
}

- (void)loadView
{
    [super loadView];
    
}
#pragma mark 快进
-(void)forwardDidTouch:(id)sender
{
    if(_moviePosition+10 < _record.allTime-2)
    {
        [self setMoviePosition: _moviePosition + 10];
    }
}
#pragma mark 快退
-(void)rewindDidTouch:(id)sender
{
    if (_moviePosition - 10 > 0 )
    {
        [self setMoviePosition: _moviePosition - 10];
    }
}
#pragma mark 播放与暂停
-(void)playDidTouch:(id)sender
{
    if (_decoder)
    {
        if (self.playing)
        {
            [self pause];
        }
        else
        {
            [self play];
        }
    }
    else
    {
        __weak PlayNetViewController *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^
       {
           [weakSelf decoderInfo];
       });
    }
}

-(void)initToolBar
{
    [self.view setBackgroundColor:RGB(255, 255, 255)];
    
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenWidth,44)];
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topHUD];
    _topHUD.alpha = 1;
    [_topHUD setBackgroundColor:[UIColor clearColor]];
    
    UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, 43, kScreenWidth, 1)];
    [lineView setBackgroundColor:[UIColor grayColor]];
    [_topHUD addSubview:lineView];
    lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    UIView *alphView = [[UIView alloc] initWithFrame:_topHUD.bounds];
    alphView.tag = 1010;
    [alphView setBackgroundColor:RGB(255,255,255)];
    [alphView setAlpha:0.5f];
    [_topHUD addSubview:alphView];
    [_topHUD setUserInteractionEnabled:YES];
    alphView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(5, 5, 30, 30);
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch:)
          forControlEvents:UIControlEventTouchUpInside];
    [_topHUD addSubview:_doneButton];

    _lblName = [[UILabel alloc] initWithFrame:Rect(30,13,kScreenWidth-60,15)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:_record.strDevNO];
    [_lblName setFont:[UIFont systemFontOfSize:15.0f]];
    [_lblName setTextColor:[UIColor blackColor]];
    [_topHUD addSubview:_lblName];
    
    _downHUD = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight-80+HEIGHT_MENU_VIEW(20, 0),kScreenWidth, 80)];
    _downHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_downHUD];
    _downHUD.alpha = 1.0f;
    [_downHUD setBackgroundColor:[UIColor clearColor]];
    [_downHUD setUserInteractionEnabled:YES];
    

    UIView *lineView1 = [[UIView alloc] initWithFrame:Rect(0, 0, kScreenWidth, 1)];
    [lineView1 setBackgroundColor:[UIColor grayColor]];
    [_downHUD addSubview:lineView1];
    lineView1.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIView *downAlphView = [[UIView alloc] initWithFrame:_downHUD.bounds];
    downAlphView.tag = 1010;
    [downAlphView setBackgroundColor:RGB(255,255,255)];
    [downAlphView setAlpha:0.5f];
    [_downHUD addSubview:downAlphView];
    downAlphView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(3,35,60,20)];
    _progressLabel.backgroundColor = [UIColor clearColor];
    _progressLabel.opaque = NO;
    _progressLabel.adjustsFontSizeToFitWidth = NO;
    _progressLabel.textAlignment = NSTextAlignmentRight;
    _progressLabel.textColor = [UIColor blackColor];
    _progressLabel.text = @"00:00:00";
    _progressLabel.font = [UIFont systemFontOfSize:12.0f];
    
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(68,35,kScreenWidth-136,20)];
    _progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _progressSlider.continuous = NO;
    _progressSlider.value = 0;
    [_progressSlider setUserInteractionEnabled:YES];

    _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth-60,35,60,20)];
    _leftLabel.backgroundColor = [UIColor clearColor];
    _leftLabel.opaque = NO;
    _leftLabel.adjustsFontSizeToFitWidth = NO;
    _leftLabel.textAlignment = NSTextAlignmentLeft;
    _leftLabel.textColor = [UIColor blackColor];
    _leftLabel.font = [UIFont systemFontOfSize:12.0f];
    _leftLabel.text = @"-99:59:59";
    _leftLabel.font = [UIFont systemFontOfSize:12];
    _leftLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    [_downHUD addSubview:_progressLabel];
    [_downHUD addSubview:_progressSlider];
    [_downHUD addSubview:_leftLabel];
    

    
    _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playBtn setImage:[UIImage imageNamed:@"realplay"] forState:UIControlStateNormal];
    [_playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
    [_playBtn addTarget:self action:@selector(playDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_playBtn];
    
    UIButton *rewindBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rewindBtn setImage:[UIImage imageNamed:@"rewind"] forState:UIControlStateNormal];
    [rewindBtn setImage:[UIImage imageNamed:@"rewind_h"] forState:UIControlStateHighlighted];
    [rewindBtn addTarget:self action:@selector(rewindDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:rewindBtn];
    
    
    UIButton *forwardBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [forwardBtn setImage:[UIImage imageNamed:@"forward"] forState:UIControlStateNormal];
    [forwardBtn setImage:[UIImage imageNamed:@"forward_h"] forState:UIControlStateHighlighted];
    [forwardBtn addTarget:self action:@selector(forwardDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:forwardBtn];
    
    _playBtn.frame = Rect(kScreenWidth/2,  2, 30, 30);//30
    rewindBtn.frame = Rect(kScreenWidth/2-50, 2, 30, 30);
    forwardBtn.frame = Rect(kScreenWidth/2+50, 2, 30, 30);
    
    _playBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    rewindBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    forwardBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

#pragma mark 退出
-(void)doneDidTouch:(NSNotification*)notify
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    }];
}
-(void)initGesture
{
    //添加单击与双击的手势,单击HUD隐藏与显示切换    双击图片渲染比例填充
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleNetPlay:)];
    
    _tapGestureRecognizer.numberOfTapsRequired = 1; // 单击
    
    _doubleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleNetPlay:)];
    
    _doubleRecognizer.numberOfTapsRequired = 2; // 双击
    //双击优先单击出发
    [_tapGestureRecognizer requireGestureRecognizerToFail:_doubleRecognizer];
    
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    
    [self.view addGestureRecognizer:_doubleRecognizer];
}
- (void) showHUD: (BOOL) show
{
    _hiddenHUD = !show;
    [[UIApplication sharedApplication] setIdleTimerDisabled:_hiddenHUD];
    [self showToolBar];
}
-(void)showToolBar
{
    _topHUD.alpha = _hiddenHUD ? 0 : 1;
    _downHUD.alpha = _hiddenHUD ? 0 : 1;
}
-(void)viewDidLoad
{
    [super viewDidLoad];
    _dispatchQueue = dispatch_queue_create("decoder", DISPATCH_QUEUE_SERIAL);
    _videoFrames    = [NSMutableArray array];
    [self.view setUserInteractionEnabled:YES];
    //隐藏status bar 还需要设置一个方法  与 prefersStatusBarHidden配对使用
    [[UIApplication sharedApplication] setStatusBarHidden:YES];//隐藏status bar
    [self initToolBar];
    [self initGesture];
    _maxBufferedDuration = 1.0;
    _minBufferedDuration = 0.1;
    
    bIsFull = NO;
    
/*
  视频解码思路:
    1.先创建XCDecoder，然后传入文件路径
    2.确定流媒体文件没有错误之后，开启解码线程
    3.获取到视频流中，视频的宽与高，然后创建openglView,设置贴图类型
    4.
*/
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}
-(void)handleNetPlay:(UITapGestureRecognizer*)tapGesture
{
    
    if (tapGesture.state == UIGestureRecognizerStateEnded)
    {
//        CGPoint point = [tapGesture locationInView:self.view];
//        if (point.y < 40 || point.y > _downHUD.frame.origin.y)
//        {
//            
//        }
        if (tapGesture == _tapGestureRecognizer)
        {
            [self showHUD: _hiddenHUD];
        }
        else if (tapGesture == _doubleRecognizer)
        {
            bIsFull = !bIsFull;
            if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
                [self setHorizontalFrame];
            }
            else
            {
                [self setVerticalFrame];
            }
        }
    }
}
#pragma mark view显示的时候
- (void) viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear");
    [super viewDidAppear:animated];
    [self updateHUD];
    __weak PlayNetViewController *__weakSelf = self;
    _leftLabel.text = formatTimeInterval(_record.allTime,NO);
    dispatch_async(dispatch_get_global_queue(0, 0), ^
    {
       [__weakSelf decoderInfo];
    });
}
#pragma mark   解码的开始片段   初始化解码器，传入文件路径查看是否有错误
-(void)decoderInfo
{
    _decoder = [[XCDecoder alloc] init];
    NSError *error=nil;
    [_decoder openDecoder:_record.strFile error:&error];
    _decoder.allTime = _record.allTime;
    if (error)
    {
        DLog(@"%d--%@",error.code,error.description);
        DLog(@"提示错误消息");
        return ;
    }
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    __weak PlayNetViewController *wearSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
   //     [ProgressHUD dismiss];
        [wearSelf play];
    });
}
#pragma mark 开启解码线程启动工作,先获取解码操作
/*
    考虑修改此方法，在XCDecoder创建的时候就能判断，打开文件或者网络流是否成功
    在打开成功之后，就可以创建视频文件了
*/
-(void)play
{
    if (self.playing)
    {
        return;
    }
    self.playing = YES;
    _decoding = NO;
    _tickCorrectionTime = 0;
    _tickCounter = 0;
    _disableUpdateHUD = NO;
    _progressSlider.enabled = YES;
    __weak UIButton *btnPlay = _playBtn;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        btnPlay.selected = YES;
    });
    
    [self asyncDecodeFrames];
    __weak PlayNetViewController *wearSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [wearSelf tick];
    });
    [self initGlView];
}

- (void) pause
{
    if (!self.playing)
        return;
    __weak UIButton *btnPlay = _playBtn;
    dispatch_async(dispatch_get_main_queue(), ^{
        btnPlay.selected = NO;
    });
    self.playing = NO;
    NSLog(@"pause movie");
}

- (void) handlePan: (UIPanGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        const CGPoint vt = [sender velocityInView:self.view];
        const CGPoint pt = [sender translationInView:self.view];
        const CGFloat sp = MAX(0.1, log10(fabsf(vt.x)) - 1.0);
        const CGFloat sc = fabsf(pt.x) * 0.33 * sp;
        if (sc > 10) {
            
            const CGFloat ff = pt.x > 0 ? 1.0 : -1.0;
            [self setMoviePosition: _moviePosition + ff * MIN(sc, 600.0)];
        }
    }
}

#pragma mark 解码主要方法
/*
 首先贴图,然后判断是否退出视频,查看剩余的frame 集合,如果个数小于10就开启解码现在
 isEOF码流末尾的标志
 不设等待时间,直接贴图  考虑分解此方法，修改成解码线程持续运行，在当frame数量固定值的时候
 解码线程休整一段时间
*/
-(void)tick
{
    if (_buffered && ((_bufferedDuration > _minBufferedDuration) || _decoder.isEOF)) {
        
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
        if (!leftFrames || !(_bufferedDuration > _minBufferedDuration))
        {
            [self asyncDecodeFrames];
        }
        __weak PlayNetViewController *wearSelf = self;
        if (_decoder.isEOF && _videoFrames.count == 0 )  //码流播放完毕
        {
            dispatch_async(dispatch_get_main_queue(), ^
           {
               [wearSelf.view makeToast:@"播放完毕"];
               [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:@"播放完毕"];
           });
            return ;
        }
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.01);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [wearSelf tick];
        });
    }
    if ((_tickCounter++ % 3) == 0) {
        [self updateHUD];
    }
}
#pragma mark 视频时间戳
- (void) setMoviePositionFromDecoder
{
    _moviePosition = _decoder.position;
}

#pragma mark  更新
- (void) updateHUD
{
    if (_disableUpdateHUD)
        return;
    
    const CGFloat duration = _record.allTime;
    const CGFloat position = _moviePosition;// -_decoder.startTime;
    
    if (_progressSlider.state == UIControlStateNormal)
    {
        _progressSlider.value = position / duration;
    }
    _progressLabel.text = formatTimeInterval(position, NO);
}

#pragma mark 解码线程等待时间 
- (CGFloat) tickCorrection
{
    if (_buffered)
        return 0;
    const NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (!_tickCorrectionTime)
    {
        _tickCorrectionTime = now;
        _tickCorrectionPosition = _moviePosition;
        return 0;
    }
    NSTimeInterval dPosition = _moviePosition - _tickCorrectionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPosition - dTime;

    if (correction > 1.f || correction < -1.f) {
        correction = 0;
        _tickCorrectionTime = 0;
    }
    
    return correction;
}


#pragma mark 视频渲染opengl
//从_videoFrames集合里面取出一个frame,然后移除，动作加锁,如果frame正确，那么渲染图片
- (CGFloat) presentFrame
{
    CGFloat interval = 0;
    KxVideoFrame *frame;
    @synchronized(_videoFrames)
    {
        if (_videoFrames.count > 0) {
            frame = _videoFrames[0];
            [_videoFrames removeObjectAtIndex:0];
            _bufferedDuration -= frame.duration;
        }
    }
    if (frame)
    {
        //修改成OPENGL 贴图RGB与YUV两种方式  现在固定YUV方式
        [_glView render:frame];
        _moviePosition = frame.position;
  //      DLog(@"_moviePosition:%f\n",_moviePosition);
        interval = frame.duration;
        frame = nil;
    }
    return interval;
}

#pragma mark 解码，获取文件中的frame数据,frame可以是视频与音频，暂时只处理音频部分
//解码，通过添加frame 的返回结果，决定dispatchQueue线程是否继续执行
- (void) asyncDecodeFrames
{
    if (self.decoding)
    {
        return;
    }
    __weak PlayNetViewController *wearSelf = self;
    dispatch_async(_dispatchQueue, ^{
            wearSelf.decoding = YES;
            if (!wearSelf.playing)
            {
                return ;
            }
            BOOL good = YES;
            while (good)
            {
                good = NO;
                NSArray *frames = [wearSelf.decoder decodeFrames];
                if(frames.count)
                {
                    good = [wearSelf addFrames:frames];
                }
                frames = nil;
            }
        wearSelf.decoding = NO;
    });
}
#pragma mark 判断frame是否视频帧
//如果是的则加入，如果缓存帧数小于10，返回YES,则解码函数会继续执行
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connect_p2p_fail:) name:NSCONNECT_P2P_FAIL_VC object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enter_background) name:NS_APPLITION_ENTER_BACK object:nil];
}

-(void)connect_p2p_fail:(NSNotification*)notify
{
    NSString *strMessage = notify.object;
    if ([strMessage isEqualToString:@"播放完毕"]) {
        [self stopVideo];
    }
    
}


- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}
#pragma mark 清空所有frame
- (void) freeBufferedFrames
{
    @synchronized(_videoFrames)
    {
        [_videoFrames removeAllObjects];
    }
    _bufferedDuration = 0;
}
























-(BOOL)shouldAutorotate
{
    if (IOS_SYSTEM_8) {
        return NO;
    }
    return YES;
}
#pragma mark 隐藏status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)initGlView
{
    if (_glView) {
        return ;
    }
    float height = _decoder.frameHeight/(_decoder.frameWidth/320.0f);
    frameCenter = Rect(0, kScreenHeight/2-height/2,320,height);
    _glView = [[KxMovieGLView alloc] initWithFrame:frameCenter decoder:_decoder];
    _glView.contentMode = UIViewContentModeScaleAspectFit;//UIViewContentModeScaleAspectFill;UIViewContentModeScaleAspectFit
    _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.view insertSubview:_glView atIndex:0];
    
    [_progressSlider addTarget:self
                        action:@selector(progressDidChange:)
              forControlEvents:UIControlEventValueChanged];
    
    [self setupUserInteraction];
    
}
-(void)progressDidChange:(id)sender
{
    UISlider *slider = sender;
    [self setMoviePosition:slider.value * _record.allTime];
    
}


- (void) setupUserInteraction
{


    
}
-(UIView*)frameView
{
    return _glView;
}

- (void) setMoviePosition: (CGFloat) position
{
    self.playing = NO;
    _disableUpdateHUD = YES;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [self updatePosition:position];
    });
}

- (void) updatePosition: (CGFloat) position
{
    [self freeBufferedFrames];
    position = MIN(_record.allTime - 1, MAX(0, position));
    __weak PlayNetViewController *weakSelf = self;
    
    dispatch_async(_dispatchQueue, ^{
        {
            __strong PlayNetViewController *strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf setDecoderPosition: position];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong PlayNetViewController *strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf setMoviePositionFromDecoder];
                [strongSelf play];
            }
        });
    });
}

- (void) setDecoderPosition: (CGFloat) position
{
    _decoder.position = position;
}

-(void)stopVideo
{
    _hiddenHUD = NO;
    [self showToolBar];
    _playing = NO;
    _decoding = NO;
    [_decoder releaseDecode];
    [self freeBufferedFrames];
    [_glView removeFromSuperview];
    _playBtn.selected = NO;
    _glView = nil;
    _decoder = nil;
    _progressSlider.value = 0;
    _progressSlider.enabled = NO;
    _progressLabel.text = formatTimeInterval(0, NO);
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

#pragma mark 横屏
-(void)setVerticalFrame
{
    if(IOS_SYSTEM_8)
    {
        _lblName.frame = Rect(30,13,kScreenWidth-60,15);
        _downHUD.frame = CGRectMake(0, kScreenHeight-60, kScreenWidth, 60);
        _glView.frame = self.view.frame;
        _glView.contentMode = bIsFull ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;

    }
    else
    {
        _lblName.frame = Rect(30, 13, kScreenHeight - 60, 15);
        _downHUD.frame = Rect(0, kScreenWidth-80+HEIGHT_MENU_VIEW(20, 0), kScreenHeight, 80);
        _glView.frame = Rect(0, 0,kScreenHeight, kScreenWidth);
        _glView.contentMode = bIsFull ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;

    }
    
}

#pragma mark 竖屏
-(void)setHorizontalFrame
{
    if (IOS_SYSTEM_8)
    {
        _lblName.frame = Rect(30,13,kScreenWidth-60,15);
        _downHUD.frame = Rect(0, kScreenHeight-80, kScreenWidth, 80);
        _glView.frame = bIsFull ? self.view.frame : frameCenter;
        _glView.contentMode = bIsFull ? UIViewContentModeScaleAspectFill :UIViewContentModeScaleAspectFit ;
    }else
    {
        _lblName.frame = Rect(30,13,kScreenWidth-60,15);
        _downHUD.frame = CGRectMake(0, kScreenHeight-80+HEIGHT_MENU_VIEW(20, 0),kScreenWidth, 80);
        _glView.frame = bIsFull ? self.view.frame : frameCenter;
        _glView.contentMode = bIsFull ? UIViewContentModeScaleAspectFill :UIViewContentModeScaleAspectFit ;
    }
}
#pragma mark 加入重力支持
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


@end

