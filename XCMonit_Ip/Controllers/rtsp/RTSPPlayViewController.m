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
#import "PhoneDb.h"
#import "Picture.h"
#import "RtspInfo.h"
#import "UIView+Extension.h"

@interface RTSPPlayViewController ()
{
    UIView *_topHUD;
    UILabel *_lblName;
    UIButton *_doneButton;
    UIView *_downHUD;
    UIImageView *_glView;
    CGRect   frameCenter;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UITapGestureRecognizer *_doubleRecognizer;
    
    UIPinchGestureRecognizer *pinchGesture;
    UIPanGestureRecognizer *_panGesture;
    
    dispatch_queue_t _dispatchQueue;
    
    BOOL _hiddenHUD;
    BOOL bIsFull;
    BOOL bRecord;
    BOOL bPlay;
    BOOL bExit;
    UIImageView *topViewBg;
    UIImageView *downViewBg;
    int _nCodeType;
    int _nChannel;
    int nCount;
    CGFloat lastX,lastY;
    CGFloat lastScale;
    CGFloat fWidth,fHeight;
}
@property (nonatomic,strong) NSString *devName;
@property (nonatomic,strong) RtspDecoder *rtspDecoder;
@property (nonatomic,strong) NSString *strPath;
@property (nonatomic,strong) RtspInfo *rtspInfo;
@property (nonatomic,strong) NSMutableArray *videoArray;
@property (nonatomic,strong) UIButton *btnBD;
@property (nonatomic,strong) UIButton *btnHD;

@property (nonatomic,strong) UIButton *btnRecord;
@property (nonatomic,strong) UIButton *btnShoto;
@property (nonatomic,strong) UIButton *btnPlay;
@property (nonatomic,assign) BOOL bDecoding;
@property (nonatomic,assign) BOOL bPlaying;

@end

@implementation RTSPPlayViewController

-(void)dealloc
{
    _rtspDecoder.bExit = YES;
    [_rtspDecoder releaseRtspDecoder];
    _rtspDecoder = nil;
    
}

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
    nCount = 0;
    _dispatchQueue = dispatch_queue_create("rtspDecoder", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1; // 单击
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    [self.view setUserInteractionEnabled:YES];
    _videoArray = [NSMutableArray array];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
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

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_btnPlay setSelected:YES];
    [self playVideo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectFail) name:NS_RTSP_DISCONNECT_VC object:nil];
}
-(void)connectFail
{
    __weak RTSPPlayViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__self.view makeToast:XCLocalized(@"rtspinterrup")  duration:1.5f position:@"center"];
    });
    [self stopVideo];
    [NSThread sleepForTimeInterval:0.3f];
    nCount++;
    if (nCount <=3 && !bExit)
    {
        DLog(@"RTSP重连:%d",nCount);
        [self playVideo];
    }
    
}

-(void)decodePlay
{
    if (_rtspDecoder)
    {
        _rtspDecoder = nil;
    }
    _rtspDecoder = [[RtspDecoder alloc] init];
    __weak RTSPPlayViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        if (IOS_SYSTEM_8)
        {
            [ProgressHUD show:XCLocalized(@"loading") viewInfo:weakSelf.view];
        }
        else
        {
            [ProgressHUD showPlayRight:XCLocalized(@"loading") viewInfo:weakSelf.view];
        }
        [weakSelf.btnPlay setEnabled:NO];
        [weakSelf.btnShoto setEnabled:NO];
        [weakSelf.btnRecord setEnabled:NO];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [weakSelf startPlayWithStr];
    });
}

-(void)handleTap:(UITapGestureRecognizer*)tapGesture
{
    CGPoint point = [tapGesture locationInView:self.view];
    if (point.y<50)
    {
        return ;
    }
    
    __weak RTSPPlayViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [weakSelf showHUD:_hiddenHUD];
    });
    
}
-(void)doubleView
{
    [self fullPlayMode];
}

- (void)showHUD:(BOOL)show
{
    _hiddenHUD = !show;
    _topHUD.alpha = _hiddenHUD ? 0 :1;
    _downHUD.alpha = _hiddenHUD ? 0 : 1;
}

-(void)startPlayWithStr
{
    NSError *error;
    __weak RTSPPlayViewController *weakSelf = self;
    int nStatus = 1;
    if([_rtspInfo.strType isEqualToString:@"DVR"])
    {
        nStatus = [_rtspDecoder protocolInit:_rtspInfo path:_strPath channel:_nChannel code:_nCodeType];
        
    }
    else
    {
        [_rtspDecoder openDecoder:_strPath error:&error];
    }
    if (error || nStatus !=1)
    {
        _bPlaying = NO;
        
        dispatch_async(dispatch_get_main_queue(),
        ^{
           [weakSelf.view makeToast:XCLocalized(@"connectFail")  duration:1.5f position:@"center"];
        });
        
        [self stopVideo];
        
        [NSThread sleepForTimeInterval:1.0f];
        
        nCount++;
        if (nCount <=3 && !bExit)
        {
            DLog(@"RTSP重连:%d",nCount);
            [self playVideo];
        }
        return ;
    }
    _bPlaying = YES;
    [_videoArray removeAllObjects];
    while (_bPlaying && _rtspDecoder.fps == 0)
    {
        [NSThread sleepForTimeInterval:0.03f];
    }
    DLog(@"继续");
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [weakSelf.btnPlay setEnabled:YES];
        [weakSelf.btnPlay setSelected:YES];
        [weakSelf.btnShoto setEnabled:YES];
        [weakSelf.btnRecord setEnabled:YES];
        [ProgressHUD dismiss];
        [weakSelf initGlView];
        [weakSelf playMovie];
    });
}
-(void)initGlView
{
    DLog(@"初始化glView");
    if (_rtspDecoder)
    {
        if (UIInterfaceOrientationPortrait == [UIApplication sharedApplication].statusBarOrientation)
        {
            frameCenter = Rect(0, 0,kScreenWidth,kScreenHeight);
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
        _glView = [[UIImageView alloc] initWithFrame:Rect(0, 0,fWidth, fHeight)];
        _glView.contentMode = UIViewContentModeScaleToFill;
        _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        [self.view insertSubview:_glView atIndex:0];
        [_glView setUserInteractionEnabled:YES];
        [_glView addGestureRecognizer:_panGesture];
        [_glView addGestureRecognizer:pinchGesture];
        if (_nCodeType==1) {
            [_btnBD setEnabled:NO];
            [_btnHD setEnabled:YES];
        }
        else
        {
            [_btnHD setEnabled:NO];
            [_btnBD setEnabled:YES];
        }
    }
}

-(void)asyncDecodeFrames
{
    if (_bDecoding)
        return;
    __weak RTSPPlayViewController *__weakSelf = self;
    _bDecoding = YES;
    dispatch_async(_dispatchQueue,
    ^{
       BOOL good = YES;
       while (good && __weakSelf.bPlaying)
       {
           good = NO;
           @autoreleasepool
           {
               if (!__weakSelf.bPlaying)
               {
                   DLog(@"跑出去");
                   return ;
               }
               NSArray *frames = [__weakSelf.rtspDecoder decodeFrames];
               if (frames && frames.count>0)
               {
                   @synchronized(__weakSelf.videoArray)
                   {
                       for (KxMovieFrame *frame in frames)
                       {
                           if (frame.type == KxMovieFrameTypeVideo)
                           {
                               [__weakSelf.videoArray addObject:frame];
                           }
                       }
                   }
               }
               frames = nil;
           }
       }
       __weakSelf.bDecoding = NO;
   });
}

-(void)playMovie
{
    if(_bPlaying)
    {
        KxVideoFrame *frame ;
        @synchronized(_videoArray)
        {
            if (_videoArray.count > 0)
            {
                frame = _videoArray[0];
                [_videoArray removeObjectAtIndex:0];
            }
        }
        if (frame)
        {
            KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
            UIImage *rgbImage = rgbFrame.asImage;
            __weak UIImage *__rgbImage = rgbImage;
            __weak UIImageView *__imgView = _glView;
            dispatch_sync(dispatch_get_main_queue(),
            ^{
               [__imgView setImage:__rgbImage];
            });
            rgbImage = nil;
            rgbFrame = nil;
            frame = nil;
        }
        if (_videoArray.count == 0)
        {
            [self asyncDecodeFrames];
        }
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.025 * NSEC_PER_SEC);
        __weak RTSPPlayViewController *__weakSelf = self;
        dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
        {
           [__weakSelf playMovie];
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
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,10,kScreenWidth-60,15)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:_rtspInfo.strDevName];
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [_lblName setTextColor:[UIColor blackColor]];
    [_topHUD addSubview:_lblName];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(5,2.5,44,44);
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];

    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch)
          forControlEvents:UIControlEventTouchUpInside];
    [_topHUD addSubview:_doneButton];
    
    _btnBD = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnBD setImage:[UIImage imageNamed:@"full_bd"] forState:UIControlStateNormal];
    [_btnBD addTarget:self action:@selector(switchVideoCodeInfo:) forControlEvents:UIControlEventTouchUpInside];
    _btnBD.tag = 1005;
    [_topHUD addSubview:_btnBD];
    _btnBD.frame = Rect(180, 1, 60, 48);
    _btnBD.enabled = NO;
    
    _btnHD = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnHD setImage:[UIImage imageNamed:@"full_hd"] forState:UIControlStateNormal];
    [_btnHD addTarget:self action:@selector(switchVideoCodeInfo:) forControlEvents:UIControlEventTouchUpInside];
    _btnHD.tag = 1006;
    _btnHD.frame = Rect(240, 1, 60, 48);
    [_topHUD addSubview:_btnHD];
    _btnHD.enabled = NO;
}

- (void)doneDidTouch
{
    [ProgressHUD dismiss];
    bExit = YES;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
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
    [self.view addSubview:_downHUD];

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
    
    _btnPlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnPlay setImage:[UIImage imageNamed:@"full_play"] forState:UIControlStateNormal];
    [_btnPlay setImage:[UIImage imageNamed:@"full_stop"] forState:UIControlStateSelected];
    [_btnPlay addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    _btnPlay.tag = 1001;
    
    _btnShoto = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnShoto setImage:[UIImage imageNamed:@"shotopic"] forState:UIControlStateNormal];
    [_btnShoto setImage:[UIImage imageNamed:@"shotopic_h"] forState:UIControlStateHighlighted];
    [_btnShoto addTarget:self action:@selector(shotoPic:) forControlEvents:UIControlEventTouchUpInside];
    
    _btnShoto.tag = 1003;
    
    _btnRecord = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnRecord setImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    [_btnRecord addTarget:self action:@selector(recordVideo:) forControlEvents:UIControlEventTouchUpInside];
    [_btnRecord setImage:[UIImage imageNamed:@"record_select"] forState:UIControlStateSelected];
    [_btnRecord setImage:[UIImage imageNamed:@"record_sel"] forState:UIControlStateSelected];
    
    _btnRecord.tag = 1004;
    
    [_downHUD addSubview:_btnPlay];
//    [_downHUD addSubview:_stopBtn];
    [_downHUD addSubview:_btnShoto];
    [_downHUD addSubview:_btnRecord];
    //  160
    _btnPlay.frame = Rect(55, 2, 45, 45);
  //  _stopBtn.frame =  Rect(110, 2, 45, 45);
    _btnShoto.frame =  Rect(165, 2, 45, 45);
    _btnRecord.frame = Rect(220,2, 45, 45);
    
    
    topViewBg = [[UIImageView alloc] initWithFrame:_topHUD.bounds];
    [topViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    
    downViewBg = [[UIImageView alloc] initWithFrame:_downHUD.bounds];
    [downViewBg setImage:[UIImage imageNamed:@"ptz_bg"]];
    
}

#pragma mark 抓拍
-(void)shotoPic:(UIButton *)btn
{
    btn.enabled = NO;
    BOOL bReturn = [self captureToPhotoAlbumNew:_glView name:_rtspInfo.strDevName];
    __weak RTSPPlayViewController *__playView = self;
    if (bReturn)
    {
        dispatch_async(dispatch_get_main_queue(),
       ^{
           [__playView.view makeToast:XCLocalized(@"captureS") duration:1.5f position:@"center"];
       });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__playView.view makeToast:XCLocalized(@"captureF") duration:1.5f position:@"center"];
        });
    }
    [self performSelector:@selector(setBtnEnYes:) withObject:btn afterDelay:1.5];
}

-(void)setBtnEnYes:(id)sender
{
    UIButton *btn  = (UIButton*)sender;
    btn.enabled = YES;
}

#pragma mark 
-(void)recordVideo:(UIButton*)btn
{
    if (bRecord)
    {
        bRecord = NO;
        __weak RTSPPlayViewController *__self = self;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__self.rtspDecoder stopRecord];
            __self.btnRecord.selected = NO;
            [__self.view makeToast:XCLocalized(@"stopRecord") duration:1.5f position:@"center"];
        });
    }
    else
    {
        btn.enabled = NO;
        NSString *strPath = [self captureRecord:_glView];
        
        [_rtspDecoder recordStart:strPath name:_rtspInfo.strDevName];
        
        bRecord = YES;
        _btnRecord.selected = YES;
        __weak RTSPPlayViewController *__self = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [__self.view makeToast:XCLocalized(@"startRecord") duration:1.5f position:@"center"];
        });
        [self performSelector:@selector(setBtnEnYes:) withObject:btn afterDelay:1.5f];
    }
}

-(NSString*)capturePhone:(NSString*)strType
{
    NSString *strDir = [kLibraryPath stringByAppendingPathComponent:strType];
    NSDate *senddate=[NSDate date];
    //创建一个目录  //shoto
    if(![[NSFileManager defaultManager] fileExistsAtPath:strDir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDir withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDir] setResourceValue: [NSNumber numberWithBool: YES]
                                                  forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd"];
    NSString *strDirYear = [strDir stringByAppendingPathComponent:[fileformatter stringFromDate:senddate]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:strDirYear])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDirYear withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDirYear] setResourceValue: [NSNumber numberWithBool: YES]
                                                      forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    return strDir;
}

-(NSString*)captureRecord:(UIImageView*)imageView
{
    UIImage *image = imageView.image;
    NSDate *senddate=[NSDate date];
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    
    [fileformatter setDateFormat:@"YYYY-MM-dd"];//年月日格式
    
    NSString *strDir = [self capturePhone:@"record"];//检测是否有文件，如果没有则创建一个
    
    NSString *strDirYear = [fileformatter stringFromDate:senddate];//字符串年月日
    
    [fileformatter setDateFormat:@"HHmmss"];//时分秒格式
    
    NSString *fileName = [strDirYear stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@.jpg",[fileformatter stringFromDate:senddate]]];//生成年－月－日/时分秒.jpg的格式
    
    NSString *strPath = [strDir stringByAppendingPathComponent:fileName];//与Library路径组合
    
    [UIImageJPEGRepresentation(image,1.0f) writeToFile:strPath atomically:YES];//将图片数据写入路径
    
    [[NSURL fileURLWithPath:strPath] setResourceValue: [NSNumber numberWithBool: YES]
                                               forKey: NSURLIsExcludedFromBackupKey error:nil];//路径防icloud拷贝
    return fileName;
}

-(void)playVideo
{
    if(_bPlaying)
    {
        [self stopVideo];
    }
    else
    {
         [self decodePlay];
    }
}

-(void)closeView
{
    __weak RTSPPlayViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [weakSelf threadClose];
    });
}
-(void)threadClose
{
    _rtspDecoder.bExit = YES;
    [NSThread sleepForTimeInterval:0.1f];
    _rtspDecoder = nil;
}
#pragma mark 视频停止
-(void)stopVideo
{
    _bPlaying = NO;
    _bDecoding = NO;
    [_rtspDecoder releaseRtspDecoder];
    __weak RTSPPlayViewController *weakSelf = self;
    __weak UIImageView *__imageView = _glView;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [ProgressHUD dismiss];
        [weakSelf updateImage:nil];
        [__imageView removeFromSuperview];
    
        [weakSelf.btnPlay setEnabled:YES];
        [weakSelf.btnPlay setSelected:NO];
        [weakSelf.btnRecord setEnabled:NO];
        [weakSelf.btnShoto setEnabled:NO];
        [weakSelf.btnHD setEnabled:NO];
        [weakSelf.btnBD setEnabled:NO];
    });
    bPlay = NO;
    [NSThread sleepForTimeInterval:0.3f];
    _glView = nil;
    _rtspDecoder = nil;
}
-(id)initWithContentRtsp:(RtspInfo*)rtspInfo channel:(NSInteger)nChannel
{
    self = [super init];
    if(self)
    {
        _rtspInfo = rtspInfo;
        _nCodeType = 1;
        if ([rtspInfo.strType isEqualToString:@"IPC"])//IPC默认子码流
        {
            _nCodeType = 1;
        }
        _nChannel = (int)nChannel;
        [self setRtspPath];
    }
    return  self;
}

-(void)setRtspPath
{
    NSString *strPath = nil;
    NSString *strAdmin = nil;
    if ([_rtspInfo.strUser isEqualToString:@""])
    {
        strAdmin = @"";
    }
    else
    {
        strAdmin = [NSString stringWithFormat:@"%@:%@@",_rtspInfo.strUser,_rtspInfo.strPwd];
    }
    if ([_rtspInfo.strType isEqualToString:@"IPC"])
    {
        strPath = [NSString stringWithFormat:@"rtsp://%@%@:%d/%d",strAdmin,_rtspInfo.strAddress,(int)_rtspInfo.nPort,_nCodeType];//主码流
    }
    else if([_rtspInfo.strType isEqualToString:@"DVR"])
    {
        strPath = [NSString stringWithFormat:@"rtsp://%@%@:%d/%d/trackID=%d",strAdmin,_rtspInfo.strAddress,(int)_rtspInfo.nPort,_nChannel,_nCodeType];
    }
    else
    {
        strPath = [NSString stringWithFormat:@"rtsp://%@%@:%d/%d%d",strAdmin,_rtspInfo.strAddress,(int)_rtspInfo.nPort,_nChannel,_nCodeType];
    }
    _strPath = strPath;
    DLog(@"链接地址:%@",_strPath);
}

#pragma mark 隐藏status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
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

    
    _topHUD.frame = Rect(0, 0, fWidth, 49);
    
    topViewBg.frame=_topHUD.bounds;
    
    [_topHUD insertSubview:topViewBg atIndex:0];
    
    [_lblName setTextColor:[UIColor whiteColor]];
    _lblName.frame = Rect(50, 15, fWidth - 160, 20);
    _downHUD.frame = Rect(0, fHeight-50, fWidth, 50);
    [_lblName setTextAlignment:NSTextAlignmentLeft];
    
    _btnBD.frame = Rect(fWidth-120, 0, 60, 48);
    _btnHD.frame = Rect(fWidth-60, 0, 60, 48);
    

    _glView.frame = Rect(0, 0,fWidth, fHeight);
    _glView.contentMode = UIViewContentModeScaleToFill;
    
    
    [_downHUD insertSubview:downViewBg atIndex:0];
    downViewBg.frame = _downHUD.bounds;
    
    _btnPlay.frame =   Rect(fWidth-180, 0 , 60, 48);
    _btnShoto.frame =  Rect(fWidth-120, 0 , 60, 48);
    _btnRecord.frame = Rect(fWidth-60, 0 , 60, 48);

    [_btnShoto setImage:[UIImage imageNamed:@"full_snap"] forState:UIControlStateNormal];
    [_btnRecord setImage:[UIImage imageNamed:@"full_record"] forState:UIControlStateNormal];

}

#pragma mark 竖屏
-(void)setHorizontalFrame
{
    _hiddenHUD = NO;
    _topHUD.alpha = _hiddenHUD ? 0 :1;
    _downHUD.alpha = _hiddenHUD ? 0 : 1;
    
    _lblName.frame = Rect(80,10,kScreenWidth-160,15);
    _downHUD.frame = Rect(0, kScreenHeight-50,kScreenWidth, 50);
    _glView.frame = Rect(0, 0,kScreenWidth, kScreenHeight);
    
    _btnPlay.frame =   Rect(0,   0, 60, 48);
 //   _stopBtn.frame =   Rect(60,  0, 60, 48);
    _btnShoto.frame =  Rect(120, 0, 60, 48);
    _btnRecord.frame = Rect(180, 0, 60, 48);
    _glView.contentMode = UIViewContentModeScaleAspectFit;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

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

-(BOOL)captureToPhotoAlbumNew:(UIImageView *)imageView name:(NSString*)devName
{
    UIImage *image = imageView.image;//修改方式
    
    NSDate *senddate=[NSDate date];
    
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd"];//年月日格式
    PictureModel *picture = [[PictureModel alloc] init];
    picture.strTime = [fileformatter stringFromDate:senddate];//先创建年月日记录
    
    NSString *strDir = [self capturePhone:@"shoto"];//Library路径
    
    NSString *strDirYear = [strDir stringByAppendingPathComponent:[fileformatter stringFromDate:senddate]];//Library与年月日格式组合
    
    [fileformatter setDateFormat:@"HHmmss"];//时分秒格式
    
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[fileformatter stringFromDate:senddate]];//时分秒的时间格式,数据库中保存成文件
    
    NSString *strPath = [strDirYear stringByAppendingPathComponent:fileName];//整体路径整合
    
    BOOL result = [UIImageJPEGRepresentation(image,1.0f) writeToFile:strPath atomically:YES];
    BOOL success = [[NSURL fileURLWithPath:strPath] setResourceValue: [NSNumber numberWithBool: YES]
                                                              forKey: NSURLIsExcludedFromBackupKey error:nil];
    picture.strFile = fileName;//记录文件名
    picture.strDevName = devName;//记录设备名
    if (result&&success)
    {
        [PhoneDb insertRecord:picture];
        return  YES;
    }
    else
    {
        return NO;
    }
}
-(CGAffineTransform)transformView
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft)
    {
        return CGAffineTransformMakeRotation(M_PI*1.5);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI/2);
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGAffineTransformMakeRotation(-M_PI);
    } else {
        return CGAffineTransformIdentity;
    }
}

-(void)fullPlayMode
{
    if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
    {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
        CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        CGRect frame = [UIScreen mainScreen].applicationFrame;
        
        if(IOS_SYSTEM_8)
        {
            CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.height/2), frame.origin.y + ceil(frame.size.width/2));
            self.view.center = center;
            self.view.transform = [self transformView];
            self.view.bounds = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        }
        else
        {
            CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width/2), frame.origin.y + ceil(frame.size.height/2));
            self.view.center = center;
            self.view.transform = [self transformView];
            self.view.bounds = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
        }
        [UIView commitAnimations];
    }
    else
    {
        [self setViewH];
    }
}

-(void)setViewH
{
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width/2), frame.origin.y + ceil(frame.size.height/2));
    self.view.center = center;
    
    self.view.transform = [self transformView];
    self.view.bounds = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    [UIView commitAnimations];
}


-(void)switchVideoCodeInfo:(UIButton*)btnSender
{
    btnSender.enabled = NO;
    if (btnSender.tag == 1005)//点击的是标清按钮
    {
        [self stopVideo];
        _nCodeType = 1;
        [self setRtspPath];
        [self playVideo];
        _btnHD.enabled = YES;
    }
    else //高清按钮
    {
        [self stopVideo];
        _nCodeType = 0;
        [self setRtspPath];
        [self playVideo];
        _btnBD.enabled = YES;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setVerticalFrame];
}

@end
