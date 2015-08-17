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
#import "UIView+Extension.h"
NSString * const KxMovieParameterMinBufferedDuration = @"KxMovieParameterMinBufferedDuration";
NSString * const KxMovieParameterMaxBufferedDuration = @"KxMovieParameterMaxBufferedDuration";
NSString * const KxMovieParameterDisableDeinterlacing = @"KxMovieParameterDisableDeinterlacing";

////////////////////////////////////////////////////////////////////////////////

static NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    seconds = MAX(0, seconds);
    
    int s = seconds;
    int m = s / 60;
    int h = m / 60;
    
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
    BOOL _hiddenHUD;//隐藏标志hud
    BOOL _buffered;//buffered判断
    
    NSMutableArray *_videoFrames;//码流信息
    dispatch_queue_t _dispatchQueue;
    
    
    UITapGestureRecognizer *_tapGestureRecognizer;
//    UITapGestureRecognizer *_doubleRecognizer;
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
    UIPinchGestureRecognizer *pinchGesture;
    UIPanGestureRecognizer *_panGesture;
    UILabel *_progressLabel;
    UILabel *_leftLabel;
    UILabel *_lblName;
    
    UIButton *_playBtn;//播放  停止按钮
    UIButton *_rewindBtn;//快退与快进
    UIButton *_forwardBtn;
    CGFloat lastX,lastY;
    CGFloat lastScale;
    CGFloat fWidth,fHeight;
}
@property (nonatomic,assign) BOOL pausing;//暂停
@property (readwrite) BOOL playing;//播放标志
@property (readwrite) BOOL decoding;//解码
@property (nonatomic,strong) NSString *strPath;//进度
@property (nonatomic,strong) XCDecoder *decoder;//解码类
@property (nonatomic,strong) RecordModel *record;//录像记录
@property (nonatomic,strong) KxMovieGLView *glView;;//opengl view

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
    //    id<KxAudioManager> audioManager = [KxAudioManager audioManager];
    //    [audioManager activateAudioSession];
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
    DLog(@"已经释放了play Net");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)loadView
{
    [super loadView];
    
}
#pragma mark 快进
-(void)forwardDidTouch:(id)sender
{
    if(_moviePosition+_record.allTime*0.2 < _record.allTime)
    {
        
        [self setMoviePosition: _moviePosition + _record.allTime*0.2];
    }
}
#pragma mark 快退
-(void)rewindDidTouch:(id)sender
{
    if (_moviePosition - _record.allTime*0.2 > 0 )
    {
        [self setMoviePosition: _moviePosition - _record.allTime*0.2];
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
            self.pausing = YES;
        }
        else
        {
            [self play];
            _pausing = NO;
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


-(void)initToolBar_1
{
    [self.view setBackgroundColor:RGB(255, 255, 255)];
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenWidth,44)];
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topHUD];
    _topHUD.alpha = 1;
    
    UIImageView *topViewBg = [[UIImageView alloc] initWithFrame:_topHUD.bounds];
    [topViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    [_topHUD addSubview:topViewBg];
    topViewBg.tag = 1008;
    
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
    
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(0, 0, 40, 40);
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    _doneButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch)
          forControlEvents:UIControlEventTouchUpInside];
    [_topHUD addSubview:_doneButton];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,15,kScreenWidth-60,20)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:_record.strDevNO];
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [_lblName setTextColor:[UIColor whiteColor]];
    [_topHUD addSubview:_lblName];
    
    _downHUD = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight-80+HEIGHT_MENU_VIEW(20, 0),kScreenWidth, 80)];
    _downHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_downHUD];
    _downHUD.alpha = 1.0f;
    [_downHUD setBackgroundColor:[UIColor clearColor]];
    [_downHUD setUserInteractionEnabled:YES];
    
    UIImageView *downViewBg = [[UIImageView alloc] initWithFrame:_downHUD.bounds];
    [downViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    [_downHUD addSubview:downViewBg];
    downViewBg.tag = 1008;
    
    UILabel *sLine3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.4, kScreenWidth, 0.1)];
    sLine3.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.5, kScreenWidth, 0.1)] ;
    sLine4.backgroundColor = [UIColor whiteColor];
    sLine3.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine4.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [_downHUD addSubview:sLine3];
    [_downHUD addSubview:sLine4];
    
    _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(3,5,60,20)];
    _progressLabel.backgroundColor = [UIColor clearColor];
    _progressLabel.opaque = NO;
    _progressLabel.adjustsFontSizeToFitWidth = NO;
    _progressLabel.textAlignment = NSTextAlignmentRight;
    _progressLabel.textColor = [UIColor whiteColor];
    _progressLabel.text = @"00:00:00";
    _progressLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0f];
    
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(68,5,kScreenWidth-136,20)];
    
    _progressSlider.continuous = NO;
    _progressSlider.value = 0;
    [_progressSlider setUserInteractionEnabled:YES];
    
    _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth-60,5,60,20)];
    _leftLabel.backgroundColor = [UIColor clearColor];
    _leftLabel.opaque = NO;
    _leftLabel.adjustsFontSizeToFitWidth = NO;
    _leftLabel.textAlignment = NSTextAlignmentLeft;
    _leftLabel.textColor = [UIColor grayColor];
    _leftLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0f];
    _leftLabel.text = @"-99:59:59";
    _leftLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
    
    
    [_downHUD addSubview:_progressLabel];
    [_downHUD addSubview:_progressSlider];
    [_downHUD addSubview:_leftLabel];
    
    
    
    _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playBtn setImage:[UIImage imageNamed:@"record_play"] forState:UIControlStateNormal];
    [_playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
    [_playBtn addTarget:self action:@selector(playDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_playBtn];
    _playBtn.tag = 1001;
    
    _rewindBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_rewindBtn setImage:[UIImage imageNamed:@"rewind"] forState:UIControlStateNormal];
    [_rewindBtn setImage:[UIImage imageNamed:@"rewind_h"] forState:UIControlStateHighlighted];
    [_rewindBtn addTarget:self action:@selector(rewindDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_rewindBtn];
    _rewindBtn.tag = 1002;
    
    
    _forwardBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_forwardBtn setImage:[UIImage imageNamed:@"forward"] forState:UIControlStateNormal];
    [_forwardBtn setImage:[UIImage imageNamed:@"forward_h"] forState:UIControlStateHighlighted];
    [_forwardBtn addTarget:self action:@selector(forwardDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_forwardBtn];
    _forwardBtn.tag = 1003;
    
    _playBtn.frame = Rect(kScreenWidth/2,  2, 30, 30);
    _rewindBtn.frame = Rect(kScreenWidth/2-50, 2, 30, 30);
    _forwardBtn.frame = Rect(kScreenWidth/2+50, 2, 30, 30);
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

-(void)initToolBar
{
    [self.view setBackgroundColor:RGB(255, 255, 255)];
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenWidth,44)];
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topHUD];
    _topHUD.alpha = 1;
    [_topHUD setBackgroundColor:[UIColor clearColor]];
    
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 43, kScreenWidth, 0.5)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 43.5, kScreenWidth, 0.5)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [_topHUD addSubview:sLine1];
    [_topHUD addSubview:sLine2];
    
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
    _doneButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch)
          forControlEvents:UIControlEventTouchUpInside];
    [_topHUD addSubview:_doneButton];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,15,kScreenWidth-60,20)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:_record.strDevNO];
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [_lblName setTextColor:[UIColor blackColor]];
    [_topHUD addSubview:_lblName];
    
    _downHUD = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight-80+HEIGHT_MENU_VIEW(20, 0),kScreenWidth, 80)];
    _downHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_downHUD];
    _downHUD.alpha = 1.0f;
    [_downHUD setBackgroundColor:[UIColor clearColor]];
    [_downHUD setUserInteractionEnabled:YES];
    
    
    UILabel *sLine3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 0.5)];
    sLine3.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.5, kScreenWidth, 0.5)] ;
    sLine4.backgroundColor = [UIColor whiteColor];
    sLine3.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine4.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [_downHUD addSubview:sLine3];
    [_downHUD addSubview:sLine4];
    
    UIView *downAlphView = [[UIView alloc] initWithFrame:_downHUD.bounds];
    downAlphView.tag = 1010;
    [downAlphView setBackgroundColor:RGB(255,255,255)];
    [downAlphView setAlpha:0.5f];
    [_downHUD addSubview:downAlphView];
    downAlphView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(3,5,60,20)];
    _progressLabel.backgroundColor = [UIColor clearColor];
    _progressLabel.opaque = NO;
    _progressLabel.adjustsFontSizeToFitWidth = NO;
    _progressLabel.textAlignment = NSTextAlignmentRight;
    _progressLabel.textColor = [UIColor blackColor];
    _progressLabel.text = @"00:00:00";
    _progressLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0f];
    
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(68,5,kScreenWidth-136,30)];
    
    _progressSlider.continuous = NO;
    _progressSlider.value = 0;
    [_progressSlider setUserInteractionEnabled:YES];
    
    _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth-60,35,60,20)];
    _leftLabel.backgroundColor = [UIColor clearColor];
    _leftLabel.opaque = NO;
    _leftLabel.adjustsFontSizeToFitWidth = NO;
    _leftLabel.textAlignment = NSTextAlignmentLeft;
    _leftLabel.textColor = [UIColor blackColor];
    _leftLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0f];
    _leftLabel.text = @"-99:59:59";
    _leftLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
    
    
    [_downHUD addSubview:_progressLabel];
    [_downHUD addSubview:_progressSlider];
    [_downHUD addSubview:_leftLabel];
    
    _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playBtn setImage:[UIImage imageNamed:@"realplay"] forState:UIControlStateNormal];
    [_playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
    [_playBtn addTarget:self action:@selector(playDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_playBtn];
    _playBtn.tag = 1001;
    
    _rewindBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_rewindBtn setImage:[UIImage imageNamed:@"rewind"] forState:UIControlStateNormal];
    [_rewindBtn setImage:[UIImage imageNamed:@"rewind_h"] forState:UIControlStateHighlighted];
    [_rewindBtn addTarget:self action:@selector(rewindDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_rewindBtn];
    _rewindBtn.tag = 1002;
    
    
    _forwardBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_forwardBtn setImage:[UIImage imageNamed:@"forward"] forState:UIControlStateNormal];
    [_forwardBtn setImage:[UIImage imageNamed:@"forward_h"] forState:UIControlStateHighlighted];
    [_forwardBtn addTarget:self action:@selector(forwardDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_forwardBtn];
    _forwardBtn.tag = 1003;
    
    _playBtn.frame = Rect(kScreenWidth/2,  40, 30, 30);//30
    _rewindBtn.frame = Rect(kScreenWidth/2-50, 40, 30, 30);
    _forwardBtn.frame = Rect(kScreenWidth/2+50, 40, 30, 30);
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

#pragma mark 退出
-(void)doneDidTouch
{
    
    [self dismissViewControllerAnimated:YES completion:
     ^{
         [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
         [[UIApplication sharedApplication] setStatusBarHidden:NO];
     }];
}
-(void)initGesture
{
    //添加单击与双击的手势,单击HUD隐藏与显示切换    双击图片渲染比例填充
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleNetPlay:)];
    
    _tapGestureRecognizer.numberOfTapsRequired = 1; // 单击
    
    //   _doubleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleNetPlay:)];
    
    //   _doubleRecognizer.numberOfTapsRequired = 2; // 双击
    //双击优先单击出发
    
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    
    //   [self.view addGestureRecognizer:_doubleRecognizer];
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
    _videoFrames = [NSMutableArray array];
    [self.view setUserInteractionEnabled:YES];
    //隐藏status bar 还需要设置一个方法  与 prefersStatusBarHidden配对使用
    [[UIApplication sharedApplication] setStatusBarHidden:YES];//隐藏status bar
    [self initToolBar_1];
    [self initGesture];
    _maxBufferedDuration = 1.0;
    _minBufferedDuration = 0.1;
    
    if(_record.nFrameBit!=0)
    {
        if (_record.nFrameBit>31)
        {
            _record.nFrameBit = 25;
        }
        _record.allTime = _record.nFramesNum/_record.nFrameBit;
    }
    NSString *strInfo = [NSString stringWithFormat:@"/%@",formatTimeInterval(_record.allTime,NO)];
    _leftLabel.text = strInfo;
    
    /*
     视频解码思路:
     1.先创建XCDecoder，然后传入文件路径
     2.确定流媒体文件没有错误之后，开启解码线程
     3.获取到视频流中，视频的宽与高，然后创建openglView,设置贴图类型
     4.
     */
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
    CGFloat fScale = [sender scale];
    
    if (_glView.frame.size.width * [sender scale] <= fWidth)
    {
        lastScale = 1.0f;
        _glView.frame = Rect(0, 0, fWidth, fHeight);
    }
    else
    {
        lastScale = 1.5f;
        CGPoint point = [sender locationInView:self.view];
        DLog(@"point:%f--%f",point.x,point.y);
        CGFloat nowWidth = glWidth*fScale>fWidth*4?fWidth*4:glWidth*fScale;
        CGFloat nowHeight =glHeight*fScale >fHeight* 4?fHeight*4:glHeight*fScale;
        
        _glView.frame = Rect(fWidth/2 - nowWidth/2,fHeight/2- nowHeight/2,nowWidth,nowHeight);
        
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}
-(void)handleNetPlay:(UITapGestureRecognizer*)tapGesture
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
            //       if(bScreen)
            //       {
            [self showHUD: _hiddenHUD];
            //        }
        }
#if 0
        else if (tapGesture == _doubleRecognizer)
        {

            if (bScreen)//横屏状态
            {
                [self setHorizontal];
                bScreen = !bScreen;
                DLog(@"%zd",self.interfaceOrientation);
            }
            else
            {
                [[UIDevice currentDevice] setValue: [NSNumber numberWithInteger:UIDeviceOrientationLandscapeRight] forKey:@"orientation"];
                [UIViewController attemptRotationToDeviceOrientation];
                CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
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
        }
    #endif
    }
}


#pragma mark view显示的时候
- (void) viewDidAppear:(BOOL)animated
{
    DLog(@"viewDidAppear");
    [super viewDidAppear:animated];
    [self updateHUD];
    __weak PlayNetViewController *__weakSelf = self;

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
    _playing = YES;
    BOOL bFlag = [_decoder openDecoder: _record.strFile error:&error];
    if(bFlag)
    {
        _decoder.allTime = _record.allTime;
        if (error)
        {
            DLog(@"%li--%@",(long)error.code,error.description);
            DLog(@"提示错误消息");
            return ;
        }
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        while(_decoder.fps==0)
        {
            if (!_playing)
            {
                return ;
            }
            [NSThread sleepForTimeInterval:0.3f];
        }
        _playing = NO;
        __weak PlayNetViewController *wearSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [wearSelf play];
            [wearSelf initGlView];
        });
    }
    else
    {
        DLog("end");
        __weak PlayNetViewController *__weakSelf = self;
        dispatch_async(dispatch_get_main_queue(),
           ^{
               [__weakSelf.view makeToast:XCLocalized(@"unFindStream")];
           });
    }
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
    _playing = YES;
    _decoding = NO;
    _tickCorrectionTime = 0;
    _tickCounter = 0;
    //   _disableUpdateHUD = NO;
    _progressSlider.enabled = YES;
    __weak UIButton *btnPlay = _playBtn;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        btnPlay.selected = YES;
    });
    if(_record.nFrameBit!=0)
    {
        _decoder.fps = _record.nFrameBit;
    }
    [self asyncDecodeFrames];
    __weak PlayNetViewController *wearSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [wearSelf tick];
    });
}

- (void) pause
{
    if (!self.playing)
    {
        return;
    }
    __weak UIButton *btnPlay = _playBtn;
    dispatch_async(dispatch_get_main_queue(), ^{
        btnPlay.selected = NO;
    });
    self.playing = NO;
    self.decoding = YES;
    
    DLog(@"pause movie");
}

- (void) handlePan: (UIPanGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        
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
               [wearSelf.view makeToast:XCLocalized(@"playOK")];
               [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:@"finish"];
            });
            return ;
        }
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.038 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
        {
           [wearSelf tick];
        });
    }
    if ((_tickCounter++ % 3) == 0)
    {
        [self updateHUD];
    }
}
#pragma mark 视频时间戳
- (void) setMoviePositionFromDecoder
{
    _moviePosition=_decoder.position;
}

#pragma mark  更新
- (void) updateHUD
{
    //    if (_disableUpdateHUD)
    //        return;
    
    const CGFloat duration = _record.allTime;
    const CGFloat position = _moviePosition;// -_decoder.startTime;
    if (_progressSlider.state == UIControlStateNormal)
    {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           _progressSlider.value = position / duration;
                       });
    }
    __weak UILabel *_weakLabel = _progressLabel;
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       _weakLabel.text = formatTimeInterval(position, NO);
                   });
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
        [_glView render:frame];
        _moviePosition = frame.position;
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
            NSArray *frames = [wearSelf.decoder record_decodeFrames];
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
    return NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connect_p2p_fail:) name:NSCONNECT_P2P_FAIL_VC object:nil];
    [self setVerticalFrame];
}

-(void)connect_p2p_fail:(NSNotification*)notify
{
    DLog(@"error:%@",notify.object);
    [self stopVideo];
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

#pragma mark 重力处理
- (BOOL)shouldAutorotate
{
    return NO;
}
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}
#pragma mark 隐藏status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)initGlView
{
    if (_glView)
    {
        return ;
    }

    _glView = [[KxMovieGLView alloc] initWithFrame:Rect(0, 0,fWidth, fHeight) decoder:_decoder];
    _glView.contentMode = UIViewContentModeScaleAspectFit;//UIViewContentModeScaleAspectFill;UIViewContentModeScaleAspectFit
    _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [_glView setUserInteractionEnabled:YES];
    _glView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view insertSubview:_glView atIndex:0];
    [_glView addGestureRecognizer:_panGesture];
    [_glView addGestureRecognizer:pinchGesture];
    [_progressSlider addTarget:self
                        action:@selector(progressDidChange:)
              forControlEvents:UIControlEventValueChanged];
}
-(void)progressDidChange:(id)sender
{
    UISlider *slider = sender;
    [self setMoviePosition:slider.value * _record.allTime];
}


-(UIView*)frameView
{
    return _glView;
}

- (void) setMoviePosition: (CGFloat) position
{
    self.playing = NO;
    _moviePosition = position;
    __weak PlayNetViewController *_weakSelf =self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void)
   {
       [_weakSelf updatePosition:position];
   });
}

- (void) updatePosition: (CGFloat) position
{
    [self freeBufferedFrames];
    position = MIN(_record.allTime, MAX(0, position));
    __weak PlayNetViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
   ^{
       [weakSelf setDecoderPosition: position];
       [weakSelf setMoviePositionFromDecoder];
       [weakSelf updateHUD];
       if(!weakSelf.pausing)
       {
           __strong PlayNetViewController *__strongSelf = weakSelf;
           dispatch_after(dispatch_time(DISPATCH_TIME_NOW,0.3 * NSEC_PER_SEC),dispatch_get_global_queue(0, 0),^{
              [__strongSelf play];
           });
       }
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
    __weak PlayNetViewController *__weakSelf = self;
    
    __weak UISlider *__weakSlider = _progressSlider;
    __weak UILabel *__weakLabel = _progressLabel;
    __weak UIButton *__weakBtn = _playBtn;
    dispatch_sync(dispatch_get_main_queue(),
    ^{
          [__weakSelf.glView removeFromSuperview];
          __weakSlider.value = 0;
          __weakSlider.enabled = NO;
          __weakLabel.text = formatTimeInterval(0, NO);
          __weakBtn.selected = NO;
    });
    _glView = nil;
    _decoder = nil;
    _moviePosition = 0;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    //e  [self doneDidTouch];
}

#pragma mark 横屏
-(void)setVerticalFrame
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
    _lblName.frame = Rect(30, 13, fWidth - 60, 15);
    _downHUD.frame = Rect(0, fHeight-80, fWidth, 80);
    _topHUD.frame = Rect(0, 0, fWidth,49);
    [_topHUD viewWithTag:1008].frame = _topHUD.bounds;
    [_downHUD viewWithTag:1008].frame = _downHUD.bounds;
    _rewindBtn.frame = Rect(50, 30, 40, 40);
    _playBtn.frame = Rect(95,  30, 40, 40);
    _forwardBtn.frame = Rect(140, 30, 40, 40);
    
    _progressSlider.frame = Rect(0,5,fWidth,20);
    _progressLabel.frame = Rect(fWidth/2-50, 40, 50, 20);
    _leftLabel.frame = Rect(fWidth/2,40,50,20);
}

#pragma mark 竖屏
-(void)setHorizontalFrame
{
    _hiddenHUD = NO;
    [self showToolBar];
    
    _progressSlider.frame = Rect(68,35,kScreenWidth-136,20);
    _leftLabel.frame = Rect(kScreenWidth-60,35,60,20);
    _lblName.frame = Rect(30,13,kScreenWidth-60,20);
    _downHUD.frame = CGRectMake(0, kScreenHeight-80+HEIGHT_MENU_VIEW(20, 0),kScreenWidth, 80);
    
    [_downHUD viewWithTag:1001].frame = Rect(kScreenWidth/2,  2, 30, 30);//30
    [_downHUD viewWithTag:1002].frame = Rect(kScreenWidth/2-50, 2, 30, 30);
    [_downHUD viewWithTag:1003].frame = Rect(kScreenWidth/2+50, 2, 30, 30);
    
    _glView.frame = frameCenter;
    _glView.contentMode = UIViewContentModeScaleAspectFit ;
}
#pragma mark 加入重力支持
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}




@end