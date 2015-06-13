//
//  PlayCloudViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/26.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "UIView+Extension.h"
#import "CloudDecode.h"
#import "PlayCloudViewController.h"
#import "TimeView.h"
#import "TimeView.h"
#import "CloudButton.h"
#import "NSDate+convenience.h"
#import "DecoderPublic.h"

@interface PlayCloudViewController ()
{
    UIView *topView;
    UIView *downView;
    UILabel *_lblName;
    CloudDecode *cloudDec;
    TimeView *timeView;
    CloudButton *btnPause;
    CloudButton *btnStop;
    CloudButton *btnCamera;
    CloudButton *btnRecord;
    CloudButton *btnDate;
    CloudButton *btnRight;
    
    UIImageView *imgView;
}
@property (nonatomic,assign) BOOL bDecoding;
@property (nonatomic,assign) BOOL bPlaying;
@property (nonatomic,strong) NSMutableArray *videoFrames;
@end

@implementation PlayCloudViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:RGB(255, 255, 255)];
    [self initBodyView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

-(void)initBodyView
{
    topView = [[UIView alloc] initWithFrame:Rect(0, 0, self.view.height,49)];
    [self.view addSubview:topView];
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, topView.frame.size.height-0.2, kScreenWidth, 0.1)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, topView.frame.size.height-0.1, kScreenWidth, 0.1)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [topView addSubview:sLine1];
    [topView addSubview:sLine2];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,15,kScreenWidth-60,20)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:@"回放"];
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    
    [_lblName setTextColor:[UIColor whiteColor]];
    [topView addSubview:_lblName];
    
    UIButton *_doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    _doneButton.frame = CGRectMake(5,2.5,44,44);
    _doneButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:_doneButton];
    
    UIImageView *topViewBg = [[UIImageView alloc] initWithFrame:topView.bounds];
    [topViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    topViewBg.tag = 10088;
    [topView insertSubview:topViewBg atIndex:0];
    
    downView = [[UIView alloc] initWithFrame:Rect(0, self.view.width-120, self.view.height,120)];
    [self.view addSubview:downView];
    
    UIImageView *downViewBg = [[UIImageView alloc] initWithFrame:downView.bounds];
    [downViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    downViewBg.tag = 10089;
    [downView insertSubview:downViewBg atIndex:0];
   
    //CloudButton
    btnPause = [[CloudButton alloc] initWithFrame:Rect(60, 200,60, 49) normal:@"play_cl" high:@"pause_cl_h" select:@"pause_cl"];
    [downView addSubview:btnPause];
    [btnPause addTarget:self action:@selector(startPlayCloud:) forControlEvents:UIControlEventTouchUpInside];
    
    btnCamera = [[CloudButton alloc] initWithFrame:Rect(btnPause.x+btnPause.width+14, 200,60, 49) normal:@"photo_cl" high:@"photo_cl_h"];
    [downView addSubview:btnCamera];
    
    btnRecord = [[CloudButton alloc] initWithFrame:Rect(btnCamera.x+btnCamera.width+14, 200,60, 49) normal:@"record_cl" high:@"record_cl_h"];
    [downView addSubview:btnRecord];
    
    btnStop = [[CloudButton alloc] initWithFrame:Rect(btnRecord.x+btnRecord.width+14, 200,60, 49) normal:@"stop_cl" high:@"stop_cl_h"];
    [downView addSubview:btnStop];
    
    btnDate = [[CloudButton alloc] initWithFrame:Rect(btnStop.x+btnStop.width+14, 200,60, 49) normal:@"date_cl" high:@"date_cl_h"];
    [downView addSubview:btnDate];
}

-(void)startPlayCloud:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected)
    {
        //播放视频
        NSString *strTime = timeView.strTime;
        BOOL bFlag = [cloudDec startVideo:strTime];
        if (!bFlag)
        {
            return ;
        }
        __weak PlayCloudViewController *__self = self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [__self startPlayCloud_gcd];
        });
    }
    else
    {
        //暂停视频
        [self stopVideo];
    }
}

-(void)cloudInit
{
    cloudDec = [[CloudDecode alloc] initWithCloud:@"9743200000001" channel:1 codeType:0];
    [cloudDec checkView:@"2015-6-9 00:00:00"];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CGFloat heightInfo = kScreenSourchHeight;
    if (IOS_SYSTEM_8)
    {
        heightInfo = kScreenSourchWidth;
    }
    NSDate *date = [NSDate date];
    NSDateFormatter *nsFormat = [[NSDateFormatter alloc] init];
    nsFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    nsFormat.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    timeView = [[TimeView alloc] initWithFrame:Rect(0, 300,heightInfo,60) time:[nsFormat stringFromDate:date]];
    
    [downView addSubview:timeView];
    timeView.frame = Rect(0,3,heightInfo,60);
    //5*60
    CGFloat fStart = heightInfo/2 - 150;
    btnPause.frame = Rect(fStart+0,65, 60, 48);
    btnCamera.frame = Rect(fStart+60,65, 60, 48);
    btnRecord.frame = Rect(fStart+120,65, 60, 48);
    btnStop.frame = Rect(fStart+180,65, 60, 48);
    btnDate.frame = Rect(fStart+240,65, 60, 48);
    
    __weak PlayCloudViewController *__self = self;
    dispatch_async(dispatch_get_global_queue(0,0),
    ^{
        [__self cloudInit];
    });
}

-(void)doneDidTouch
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGFloat fWidth,fHeight;
    if(IOS_SYSTEM_8)
    {
        fWidth = self.view.width;
        fHeight = self.view.height;
    }
    else
    {
        fWidth = self.view.height;
        fHeight = self.view.width;
    }
    
    topView.frame = Rect(0, 0, fWidth, 49);
    _lblName.frame = Rect(30, 15, fWidth-60, 20);
    [topView viewWithTag:10088].frame = topView.bounds;
    downView.frame = Rect(0, fHeight-120, fWidth, 120);
    [downView viewWithTag:10089].frame = downView.bounds;
}

-(BOOL)prefersStatusBarHidden
{
    return  YES;
}

-(BOOL)shouldAutorotate
{
    return  NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return  UIInterfaceOrientationMaskLandscapeRight;
}

-(void)startPlayCloud_gcd
{
    __weak PlayCloudViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__self initGlView];
    });
    _bPlaying = YES;
    _bDecoding = NO;
    
    while (cloudDec.fps!=30)
    {
        [NSThread sleepForTimeInterval:0.1];
    }
    
    _videoFrames = [NSMutableArray array];
    DLog(@"开始播放");
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__self startPlay];
    });
    //开始解码模块
    
}

-(void)initGlView
{
    CGFloat fWidth,fHeight;
    if (IOS_SYSTEM_8) {
        fWidth = kScreenSourchWidth;
        fHeight = kScreenSourchHeight;
    }
    else
    {
        fWidth = kScreenSourchHeight;
        fHeight = kScreenSourchWidth;
    }
    if (imgView == nil)
    {
        imgView = [[UIImageView alloc] initWithFrame:Rect(0, 0, fWidth, fHeight)];
    }
    [self.view insertSubview:imgView atIndex:0];
}

-(void)startPlay
{
    if(_bPlaying)
    {
        if(_videoFrames.count>0)
        {
            [self updatePlayUI];
        }
        if (_videoFrames.count==0)
        {
            //解码开启
            [self decodeAsync];
        }
        __weak PlayCloudViewController *__weakSelf = self;
        dispatch_time_t after = dispatch_time(DISPATCH_TIME_NOW, 0.025 * NSEC_PER_SEC );
        dispatch_after(after, dispatch_get_global_queue(0, 0),
        ^{
             [__weakSelf startPlay];
        });
    }
}

-(void)decodeAsync
{
    if (!_bPlaying || _bDecoding)
    {
        return ;
    }
    _bDecoding = YES;
    __weak PlayCloudViewController *__weakSelf = self;
    __weak CloudDecode *__decoder = cloudDec;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL bGood = YES;
        while (bGood)
        {
            NSArray *array = [__decoder decodeFrame];
            bGood = NO;
            if (array && array.count>0)
            {
                @synchronized(__weakSelf.videoFrames)
                {
                    for (KxVideoFrame *frame in array)
                    {
                        [__weakSelf.videoFrames addObject:frame];
                    }
                }
                array = nil;
            }
        }
        __weakSelf.bDecoding = NO;
    });
}

-(CGFloat)updatePlayUI
{
    CGFloat interval = 0;
    KxVideoFrame *frame;
    @synchronized(_videoFrames)
    {
        if (_videoFrames.count > 0)
        {
            frame = _videoFrames[0];
            [_videoFrames removeObjectAtIndex:0];
        }
    }
    if (frame)
    {
        KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB*)frame;
        __weak UIImageView *__imgView = imgView;
        __weak KxVideoFrameRGB *__rgbFrame = rgbFrame;
        dispatch_sync(dispatch_get_main_queue(),
        ^{
              [__imgView setImage:nil];
              [__imgView setImage:[__rgbFrame asImage]];
        });
        rgbFrame = nil;
        interval = frame.duration;
        frame = nil;
    }
    return interval;
}

-(void)stopVideo
{
    [cloudDec stopDecode];
    _bPlaying = NO;
    _bDecoding = YES;
    @synchronized(_videoFrames)
    {
        [_videoFrames removeAllObjects];
    }
    _videoFrames = nil;
    if([NSThread isMainThread])
    {
        [imgView removeFromSuperview];
    }
    else
    {
        UIImageView *__imgView = imgView;
        dispatch_async(dispatch_get_main_queue(), ^{
            [__imgView removeFromSuperview];
        });
        imgView = nil;
    }
}

-(void)dealloc
{
    _bDecoding = YES;
    _bPlaying = NO;
    [imgView removeFromSuperview];
    @synchronized(_videoFrames)
    {
        [_videoFrames removeAllObjects];
    }
    _videoFrames = nil;
}

@end
