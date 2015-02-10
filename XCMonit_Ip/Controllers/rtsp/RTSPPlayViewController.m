//
//  RTSPPlayViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RTSPPlayViewController.h"
#import "RtspDecoder.h"
#import "CaptureService.h"
#import "Toast+UIView.h"
#import "ProgressHUD.h"
#import "KxMovieGLView.h"
#import "XCNotification.h"

@interface RTSPPlayViewController ()
{
    UIView *_topHUD;
    UILabel *_lblName;
    UIButton *_doneButton;
    UIView *_downHUD;
    UIButton *_recordBtn;
    UIImageView *_glView;
    CGRect   frameCenter;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UITapGestureRecognizer *_doubleRecognizer;
    BOOL _hiddenHUD;
    BOOL bIsFull;
    BOOL bRecord;
}

@property (nonatomic,strong) RtspDecoder *rtspDecoder;
@property (nonatomic,strong) NSString *strPath;

@end

@implementation RTSPPlayViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initToolBar];
    bIsFull = NO;
    bRecord = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    _tapGestureRecognizer.numberOfTapsRequired = 1; // 单击
    _doubleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleView)];
    _doubleRecognizer.numberOfTapsRequired = 2; // 双击
    [_tapGestureRecognizer requireGestureRecognizerToFail:_doubleRecognizer];
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    [self.view addGestureRecognizer:_doubleRecognizer];
    [self.view setUserInteractionEnabled:YES];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self decodePlay];
}

-(void)decodePlay
{
    __weak RTSPPlayViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ProgressHUD show:@"正在连接"];
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [weakSelf startPlayWithStr];
    });
}

-(void)handleTap
{
    __weak RTSPPlayViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [weakSelf showHUD:_hiddenHUD];
    });
    
}
-(void)doubleView
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

- (void) showHUD:(BOOL)show
{
    _hiddenHUD = !show;
    [self showToolBar];
}

-(void)showToolBar
{
    _topHUD.alpha = _hiddenHUD ? 0 :1;
    _downHUD.alpha = _hiddenHUD ? 0 : 1;
}

-(void)startPlayWithStr
{
    NSError *error;
    __weak RTSPPlayViewController *weakSelf = self;
    [_rtspDecoder openDecoder:_strPath error:&error];
    if (error)
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [ProgressHUD dismiss];
            [weakSelf.view makeToast:@"连接失败"];
        });
        return ;
    }
    [_rtspDecoder startPlay];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [ProgressHUD dismiss];
            [weakSelf initGlView];
            [weakSelf playMovie];
    });
    
}
-(void)initGlView
{
    float height = _rtspDecoder.frameHeight/(_rtspDecoder.frameWidth/320.0f);
    frameCenter = Rect(0, kScreenHeight/2-height/2,320,height);
    _glView = [[UIImageView alloc] initWithFrame:frameCenter];
    _glView.contentMode = UIViewContentModeScaleToFill;
    _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    //    _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.view insertSubview:_glView atIndex:0];
    

}
-(void)playMovie
{
    if(_rtspDecoder.playing)
    {
        NSMutableArray *array = [_rtspDecoder getVideoArray];
        __weak RTSPPlayViewController *weakSelf = self;
        KxVideoFrame *frame ;
        if(array.count>0)
        {
            @synchronized(array)
            {
                if (array.count > 0)
                {
                    frame = array[0];
                    [array removeObjectAtIndex:0];
                }
            }
            if (frame)
            {
                KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
                UIImage *rgbImage = rgbFrame.asImage;
                __weak UIImage *_rgbImage = rgbImage;
                dispatch_async(dispatch_get_main_queue(),
                ^{
                   [weakSelf updateImage:_rgbImage];
                });
                rgbImage = nil;
                frame = nil;
            }
        }
        array = nil;
        [NSThread sleepForTimeInterval:0.01f];
        float nTime = _rtspDecoder.fps * 2;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0/nTime * NSEC_PER_SEC);
        
        dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
        {
           [weakSelf playMovie];
        });
        
    }
}
-(void)updateImage:(UIImage *)image
{
    [_glView setImage:image];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initToolBar
{
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [self initTopView];
    
    [self initButtomView];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

-(void)initTopView
{
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenHeight,44)];
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
    
    UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, 43, kScreenHeight, 1)];
    [lineView setBackgroundColor:[UIColor grayColor]];
    [_topHUD addSubview:lineView];
    lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,10,kScreenWidth-60,15)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:@"rtsp"];
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
}

- (void)doneDidTouch: (id) sender
{
    [self stopVideo];
    [self dismissViewControllerAnimated:YES completion:
     ^{
         [[UIApplication sharedApplication] setStatusBarHidden:NO];
         [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
     }];
}

#pragma mark 底部工具栏
-(void)initButtomView
{
    _downHUD = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight-50+HEIGHT_MENU_VIEW(20, 0),kScreenWidth, 50)];
    _downHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_downHUD];
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
    lineViewDown.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopBtn setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    [stopBtn setImage:[UIImage imageNamed:@"stop_h"] forState:UIControlStateHighlighted];
    [stopBtn addTarget:self action:@selector(stopVideo) forControlEvents:UIControlEventTouchUpInside];
    stopBtn.tag = 1002;
    
    UIButton *shotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [shotoBtn setImage:[UIImage imageNamed:@"shotopic"] forState:UIControlStateNormal];
    [shotoBtn setImage:[UIImage imageNamed:@"shotopic_h"] forState:UIControlStateHighlighted];
    [shotoBtn addTarget:self action:@selector(shotoPic) forControlEvents:UIControlEventTouchUpInside];
    
    shotoBtn.tag = 1003;
    _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_recordBtn setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    [_recordBtn addTarget:self action:@selector(recordVideo) forControlEvents:UIControlEventTouchUpInside];
    [_recordBtn setImage:[UIImage imageNamed:@"record_select"] forState:UIControlStateSelected];
    [_recordBtn setImage:[UIImage imageNamed:@"record_sel"] forState:UIControlStateSelected];
    
    _recordBtn.tag = 1004;
    
    [_downHUD addSubview:stopBtn];
    [_downHUD addSubview:shotoBtn];
    [_downHUD addSubview:_recordBtn];
    
    [_recordBtn setFrame:Rect(207,2, 45, 45)];
    stopBtn.frame =  Rect(87, 2, 45, 45);
    shotoBtn.frame =  Rect(147, 2, 45, 45);
}

#pragma mark 抓拍
-(void)shotoPic
{
    BOOL bFlag = [CaptureService captureToPhotoAlbum:_glView];
    if (bFlag) {
        __weak RTSPPlayViewController *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view makeToast:@"抓拍成功"];
        });
    }else
    {
        if (bFlag) {
            __weak RTSPPlayViewController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view makeToast:@"抓拍失败"];
            });
        }
    }
}


#pragma mark 
-(void)recordVideo
{
    if (bRecord)
    {
        [_rtspDecoder stopRecord];
        bRecord = NO;
        _recordBtn.selected = NO;
    }
    else
    {
        [_rtspDecoder startRecord];
        bRecord = YES;
        _recordBtn.selected = YES;
    }
}



#pragma mark 视频停止
-(void)stopVideo
{
    _rtspDecoder.playing = NO;
    _rtspDecoder = nil;
    
    __weak RTSPPlayViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf updateImage:nil];
    });
}
-(id)initWithContentPath:(NSString*)strPath
{
    self = [super init];
    if(self)
    {
        _strPath = strPath;
        _rtspDecoder = [[RtspDecoder alloc] init];
    }
    return  self;
}

#pragma mark 隐藏status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark 横屏
-(void)setVerticalFrame
{
    _lblName.frame = Rect(80, 10, kScreenHeight - 160, 15);
    _downHUD.frame = Rect(0, kScreenWidth-50, kScreenHeight, 50);
    _glView.frame = Rect(0, 0,kScreenHeight, kScreenWidth);
    [_downHUD viewWithTag:1002].frame = Rect(kScreenHeight/2-72.5, 2, 45, 45);
    [_downHUD viewWithTag:1003].frame = Rect(kScreenHeight/2-22.5, 2, 45, 45);
    [_downHUD viewWithTag:1004].frame = Rect(kScreenHeight/2+22.5,2, 45, 45);
    _glView.contentMode = bIsFull ? UIViewContentModeScaleToFill : UIViewContentModeScaleAspectFit;
}

#pragma mark 竖屏
-(void)setHorizontalFrame
{
        _lblName.frame = Rect(80,10,kScreenWidth-160,15);
        _downHUD.frame = Rect(0, kScreenHeight-50,kScreenWidth, 50);
        _glView.frame = bIsFull ? self.view.frame : frameCenter;
        [_downHUD viewWithTag:1002].frame = Rect(87, 2, 45, 45);
        [_downHUD viewWithTag:1003].frame = Rect(147, 2, 45, 45);
        [_downHUD viewWithTag:1004].frame = Rect(207,2, 45, 45);
    _glView.contentMode = bIsFull ? UIViewContentModeScaleToFill : UIViewContentModeScaleAspectFit;
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


-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
@end
