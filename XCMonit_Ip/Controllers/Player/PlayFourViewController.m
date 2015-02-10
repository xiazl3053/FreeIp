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


@interface PlayControlModel : NSObject
@property (nonatomic,strong) XCDecoderNew *decode;
//@property (nonatomic,strong) KxMovieGLView *glView;
@property (nonatomic,strong) UIImageView *glView;
@property (nonatomic,assign) NSInteger nPlayIndex;

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

@interface PlayFourViewController ()<VideoViewDelegate>
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
    //UIView nIndex bPlay
}
@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,strong) UILabel  *borderLabel;
@property (nonatomic,strong) UIScrollView *scroll;
@property (nonatomic,strong) NSMutableDictionary *decoderInfo;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) NSString *strNO;
@property (nonatomic,assign) BOOL bPlay;
@property (nonatomic,strong) DeviceInfoModel *devModel;
@property (nonatomic,assign) int nDevChannel;

@end

@implementation PlayFourViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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
        [weakSelf startPlayWithNO:__strNO channel:@"0"];
    });
}
-(void)startPlayWithNO:(NSString*)strNO channel:(NSString*)strKey
{
    PlayControlModel *playModel = [_decoderInfo valueForKey:strKey];
    if (!playModel)
    {
        playModel = [[PlayControlModel alloc] init];
        [_decoderInfo setValue:playModel forKey:strKey];
    }
    playModel.decode = [[XCDecoderNew alloc] initWithFormat:KxVideoFrameFormatRGB];
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
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        while (!weakdecode.frameWidth)
        {
            [NSThread sleepForTimeInterval:0.2f];
            if (!weakSelf.bPlay)
            {
                return ;
            }
        }
        [weakdecode startPlay];
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            [weakSelf initGlViewWithNO:__strNO channel:__strChannel];
            [weakSelf playMovieWithChannel:__strChannel];
        });
    });
}

-(void)initGlViewWithNO:(NSString *)strNO channel:(NSString*)strKey
{
    PlayControlModel *playModel = [_decoderInfo valueForKey:strKey];
    PlayControllerView *playView = (PlayControllerView*)[_array objectAtIndex:(int)playModel.nPlayIndex];
    playView.strKey = strKey;
    
    playModel.glView = [[UIImageView alloc] initWithFrame:playView.mainView.bounds];
    
    playModel.glView.contentMode = UIViewContentModeScaleAspectFit;
    
    playModel.glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [playView.mainView insertSubview:playModel.glView atIndex:0];
    
    __weak PlayControllerView *__weakPlay = playView;
    __weak PlayControlModel *_playModel = playModel;
    __weak PlayControllerView *_playView = playView;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [_playView.mainView addSubview:_playModel.glView];
        [__weakPlay.mainView hideToastActivity];
    });
    
}
-(void)playMovieWithChannel:(NSString*)strKey
{
    PlayControlModel *playInfo = [_decoderInfo valueForKey:strKey];
    if(playInfo.decode.playing)
    {
        NSMutableArray *array = [playInfo.decode getVideoArray];
        
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
                __weak PlayControlModel *__playInfo = playInfo;
                UIImage *rgbImage = rgbFrame.asImage;
                __weak UIImage *_rgbImage = rgbImage;
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [__playInfo.glView setImage:nil];
                    [__playInfo.glView setImage:_rgbImage];
                });
               rgbImage = nil;
               frame = nil;
            }
        }
        array = nil;
        [NSThread sleepForTimeInterval:0.01f];
        float nTime = playInfo.decode.fFPS * 12;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0/nTime * NSEC_PER_SEC);
        __weak PlayFourViewController *weakSelf = self;
        __block NSString* __strKey = strKey;
        dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
       {
           [weakSelf playMovieWithChannel:__strKey];
       });
        
    }
}

//view显示时加载
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectP2PFail:) name:NSCONNECT_P2P_DVR_FAIL_VC object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backModel) name:NS_APPLITION_ENTER_BACK object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view removeGestureRecognizer:doubleGesture];
//    [self.view removeGestureRecognizer:tapGesture];
}

#pragma mark 播放错误显示
-(void)connectP2PFail:(NSNotification*)notify
{
    XCDecoderNew *decoder = [notify object];
    __weak XCDecoderNew *weakDecode = decoder;
    NSString *strKey = [NSString stringWithFormat:@"%d",decoder.nChannel];
    PlayControlModel *playModel = [_decoderInfo valueForKey:strKey];
    PlayControllerView *playView = [_array objectAtIndex:playModel.nPlayIndex];
    __weak PlayControllerView *__playView = playView;
    
    dispatch_async(dispatch_get_main_queue(),
    ^{
        NSString *strInfo = [NSString stringWithFormat:@"%@",weakDecode.strError];
        [__playView.mainView makeToast:strInfo];
    });
    [self closePlayForKey:strKey];
}

#pragma mark
-(void)backModel
{
    //释放SDK
    [self stopVideo];
}


#pragma mark 停止选择的视频
-(void)stopCurVideo
{
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
    if (playModel)
    {
        [self closePlayForKey:playView.strKey];
    }
}

#pragma mark 停止所有正在播放的视频
-(void)stopVideo
{
    _bPlay = NO;
    __weak PlayFourViewController *weakSelf =self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (NSString *strKey in [weakSelf.decoderInfo allKeys])
        {
            [weakSelf closePlayForKey:strKey];
            [NSThread sleepForTimeInterval:0.5f];
        }
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)dealloc
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}
#pragma mark 禁止重力感应
-(BOOL)shouldAutorotate
{
    return NO;
}

//抓拍
-(void)shotoPic
{
  //  [CaptureService captureToPhotoAlbum:_glView];
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    DLog(@"nIndex:%d",nIndex);
    PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
    if (playModel)
    {
        BOOL bReturn = [self captureToPhotoAlbumNew:playModel.glView];
        __weak PlayControllerView *__playView = playView;
        if (bReturn)
        {
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [__playView.mainView makeToast:@"抓拍成功"];
            });
        }
        else
        {
           dispatch_async(dispatch_get_main_queue(),
           ^{
               [__playView.mainView makeToast:@"抓拍失败"];
           });
        }
    }
}

#pragma mark 录像操作
//根据设备序列号或者通道好,找寻到其中的DECODER,然后就是与ipc一样的操作
-(void)recordVideo
{
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    if (playView.bRecord)
    {
        [self stopRecord:nIndex];
    }
    else
    {
        playView.bRecord = YES;
        PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
        [playModel.decode recordStart];
        _recordBtn.selected = YES;
    }
    
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
#pragma mark 请求通道播放
-(void)channelPlay:(UIButton*)sender
{
    int nChannel = sender.tag-1000;
    
    NSString *strChannel = [NSString stringWithFormat:@"%d",nChannel];
    DLog(@"第%@个通道请求播放",strChannel);
    __weak PlayFourViewController *weakSelf = self;
    __block NSString *__strChannel = strChannel;
    //先检测该屏幕
    PlayControllerView *playView = (PlayControllerView*)[_array objectAtIndex:(int)nIndex];
    if ([playView.strKey isEqualToString:strChannel] && playView.bPlay)
    {
        return ;
    }
    if (playView.bPlay)
    {
        __weak PlayControllerView *__weakPlay = playView;
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            DLog(@"关闭通道:%@",__weakPlay.strKey);
            [weakSelf closePlayForKey:__weakPlay.strKey];
        });
        while (playView.bPlay)
        {
            [NSThread sleepForTimeInterval:0.3f];
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
        PlayControlModel *playModelNew = [[PlayControlModel alloc] init];
        playModelNew.nPlayIndex = nIndex;
        PlayControllerView *playViewNew = (PlayControllerView *)[_array objectAtIndex:nIndex];
        
        playViewNew.bPlay = YES;
        playViewNew.strKey = strChannel;
        
        [_decoderInfo setValue:playModelNew forKey:strChannel];
        __weak NSString *__strNO = _strNO;
        
        __weak PlayControllerView *__playView = playViewNew;
        dispatch_async(dispatch_get_main_queue(),
        ^{
             [__playView.mainView makeToastActivity];
        });
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            [weakSelf startPlayWithNO:__strNO channel:__strChannel];
        });
    }
    
}
#pragma mark 关闭视频
-(void)closePlayForKey:(NSString *)strKey
{
    __block NSString *strKeyCopy = strKey;
    __weak PlayFourViewController *__weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        PlayControlModel *playModel = [__weakSelf.decoderInfo valueForKey:strKeyCopy];
        if(playModel)
        {
            PlayControllerView *playView = (PlayControllerView*)[__weakSelf.array objectAtIndex:playModel.nPlayIndex];
            [playModel.decode releaseDecode];
            __weak PlayControllerView *__playView = playView;
            __weak UIImageView *__glView = playModel.glView;
            dispatch_async(dispatch_get_main_queue(),^{
                [__glView removeFromSuperview];
                [__playView.mainView hideToastActivity];
            });
            playModel.decode = nil;
            playModel.glView = nil;
            playView.bPlay = NO;
            [__weakSelf.decoderInfo removeObjectForKey:strKeyCopy];
            playView.strKey = nil;
        }
    });
}

-(void)clickView:(id)sender
{
    VideoView *view = (VideoView*)sender;
    [_borderLabel setFrame:view.frame];
    nIndex = view.nCursel;
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    if(playView.bPlay)
    {
        _recordBtn.enabled = YES;
        _recordBtn.selected = playView.bRecord ? YES : NO;
        ((UIButton*)[_downHUD viewWithTag:1002]).enabled = YES;
        ((UIButton*)[_downHUD viewWithTag:1003]).enabled = YES;
    }
    else
    {
        ((UIButton*)[_downHUD viewWithTag:1002]).enabled = NO;
        ((UIButton*)[_downHUD viewWithTag:1003]).enabled = NO;
        _recordBtn.enabled = NO;
    }
    

}
-(void)doubleClickVideo:(id)sender
{
    VideoView *view = (VideoView*)sender;
    int nTemp = view.nCursel;
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
            __weak PlayControllerView *_playView = playView;
            __weak PlayControlModel *_playModel = playModel;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_playView.mainView setFrame:Rect(0, 70, kScreenWidth, kScreenWidth)];
                [_playModel.glView removeFromSuperview];
                [_playView.mainView insertSubview:_playModel.glView atIndex:0];
            });
        }
        else
        {
            __weak PlayControllerView *_playView = playView;
            __weak PlayControlModel *_playModel = playModel;
            __weak PlayFourViewController *_weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_playView.mainView setFrame:_playView.mainRect];
                [_playModel.glView removeFromSuperview];
                [_playView.mainView insertSubview:_playModel.glView atIndex:0];
                [_weakSelf.borderLabel setFrame:view.frame];
            });
        }
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
            _borderLabel.hidden = !bFull;
            bFull = !bFull;
        }
    }
}

#pragma mark 顶部导航栏初始化
-(void)initTopView
{
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenHeight,44)];
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topHUD];
    _topHUD.alpha = 1;
    [_topHUD setBackgroundColor:[UIColor whiteColor]];

    UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, 43, kScreenWidth, 1)];
    [lineView setBackgroundColor:[UIColor grayColor]];
    [_topHUD addSubview:lineView];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,10,kScreenWidth-60,15)];
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    [_lblName setText:_strNO];
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
#pragma mark 视频矿初始化
-(void)initVideoView
{
    VideoView *_mainView1 = [[VideoView alloc] initWithFrame:Rect(1,70, kScreenWidth/2-2, kScreenWidth/2-2)];
    [self.view addSubview:_mainView1];
    _mainView1.delegate = self;
    _mainView1.nCursel = 0;
    
    VideoView *_mainView2 = [[VideoView alloc] initWithFrame:Rect(kScreenWidth/2,70, kScreenWidth/2-2, kScreenWidth/2-2)];
    [self.view addSubview:_mainView2];
    _mainView2.nCursel = 1;
    _mainView2.delegate = self;
    
    VideoView *_mainView3 = [[VideoView alloc] initWithFrame:Rect(1,_mainView2.frame.origin.y+_mainView2.frame.size.height+1, kScreenWidth/2-2, kScreenWidth/2-2)];
    [self.view addSubview:_mainView3];
    _mainView3.nCursel =2;
    _mainView3.delegate = self;
    
    VideoView *_mainView4 = [[VideoView alloc] initWithFrame:Rect(kScreenWidth/2,_mainView3.frame.origin.y,kScreenWidth/2-2,kScreenWidth/2-2)];
    [self.view addSubview:_mainView4];
    _mainView4.nCursel = 3;
    _mainView4.delegate = self;
    
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
    //滚动条
    _scroll = [[UIScrollView alloc] initWithFrame:Rect(0, mainView.frame.origin.y+mainView.frame.size.height+20, kScreenWidth, 150)];
    [self.view addSubview:_scroll];
    nOldIndex = -1;
    
    int nNumber = _nDevChannel <= 8 ? 1 : _nDevChannel/8;
    int nRow = _nDevChannel <= 8 ? _nDevChannel : 8;
    for (int i=0; i<nNumber;i++)
    {
        UIView *view = [[UIView alloc] initWithFrame:Rect(i*320, 0, 320, 130)];
        for (int j=0; j<nRow; j++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = Rect((j%4)*73+28, j/4*50+5, 45, 45);
            NSString *strInfo = [NSString stringWithFormat:@"%d",i*8+j+1];
            [btn setTitle:strInfo forState:UIControlStateNormal];
            btn.tag = 1000 + j;
            [btn setBackgroundColor:[UIColor whiteColor]];
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
            [btn setBackgroundImage:[UIImage imageNamed:@"channel"] forState:UIControlStateNormal];
            [btn setBackgroundImage:[UIImage imageNamed:@"channel_h"] forState:UIControlStateHighlighted];
            
            
            [btn addTarget:self action:@selector(channelPlay:) forControlEvents:UIControlEventTouchUpInside];
            [view addSubview:btn];
        }
        [_scroll addSubview:view];
        //
    }
    _scroll.contentSize = CGSizeMake(320*nNumber,80);
    _scroll.pagingEnabled=YES;
    [_scroll setBackgroundColor:[UIColor whiteColor]];
    [_scroll setScrollEnabled:YES];
}

#pragma mark 底部工具栏
-(void)initButtomView
{
    _downHUD = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight-50+HEIGHT_MENU_VIEW(20, 0),kScreenWidth, 50)];
    _downHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_downHUD];
    [_downHUD setBackgroundColor:RGB(255, 255, 255)];
    //[CustomNaviBarView createImgNaviBarBtnByImgNormal:@"realplay" imgHighlight:nil target:self action:@selector(playVideo)]
    
    UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, 1, kScreenWidth, 1)];
    [lineView setBackgroundColor:[UIColor grayColor]];
    [_downHUD addSubview:lineView];
    
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopBtn setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    [stopBtn setImage:[UIImage imageNamed:@"stop_h"] forState:UIControlStateHighlighted];
    [stopBtn addTarget:self action:@selector(stopCurVideo) forControlEvents:UIControlEventTouchUpInside];
    stopBtn.tag = 1002;
    
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
    
    [_recordBtn setFrame:Rect(207,2, 45, 45)];
    stopBtn.frame =  Rect(87, 2, 45, 45);
    shotoBtn.frame =  Rect(147, 2, 45, 45);
    
}

-(void)initToolBar
{
    
    [self.view setBackgroundColor:[UIColor whiteColor]];

    [self initTopView];
    
    [self initVideoView];
    
    [self initScrollView];
    
    [self initButtomView];
    
    [self.view setUserInteractionEnabled:YES];
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

#pragma mark 隐藏status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
#pragma mark 抓拍

-(UIImage *)glToUIImage:(UIView *)glView
{
    NSInteger width = glView.frame.size.width;
    NSInteger height = glView.frame.size.height;
    NSInteger myDataLength = width * height * 4;
    
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    for(int y = 0; y <height; y++)
    {
        for(int x = 0; x <width * 4; x++)
        {
            buffer2[(height-1 - y) * width * 4 + x] = buffer[y * 4 * width + x];
        }
    }
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2, myDataLength, NULL);
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef];
    return myImage;
}




-(BOOL)captureToPhotoAlbum:(UIView *)_glView
{
    UIImage *image = [self snapshot:_glView];//修改方式
    
    NSDate *senddate=[NSDate date];
    
    //创建一个目录  //shoto
    NSString *strDir = [kLibraryPath stringByAppendingPathComponent:@"shoto"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:strDir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDir withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDir] setResourceValue: [NSNumber numberWithBool: YES]
                                                  forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd"];
    //每天的记录创建一个
    NSString *strDirYear = [strDir stringByAppendingPathComponent:[fileformatter stringFromDate:senddate]];
    [fileformatter setDateFormat:@"YYYYMMddHHmmss"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:strDirYear]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDirYear withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDirYear] setResourceValue: [NSNumber numberWithBool: YES]
                                                      forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[fileformatter stringFromDate:senddate]];
    NSString *strPath = [strDirYear stringByAppendingPathComponent:fileName];
    
    BOOL result = [UIImageJPEGRepresentation(image,0.8f) writeToFile:strPath atomically:YES];
    
    BOOL success = [[NSURL fileURLWithPath:strPath] setResourceValue: [NSNumber numberWithBool: YES]
                                                              forKey: NSURLIsExcludedFromBackupKey error:nil];
    if (result&&success)
    {
        DLog(@"抓拍");
        return  YES;
    }
    else
    {
        return NO;
    }
}

- (UIImage*)snapshot:(UIView*)eaglview
{

    NSInteger x = 0, y = 0, width = eaglview.frame.size.width, height = eaglview.frame.size.height;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    NSInteger widthInPoints, heightInPoints;
    if (NULL != UIGraphicsBeginImageContextWithOptions) {
        CGFloat scale = eaglview.contentScaleFactor;
        widthInPoints = width / scale;
        heightInPoints = height / scale;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    }
    else {
        widthInPoints = width;
        heightInPoints = height;
        UIGraphicsBeginImageContext(CGSizeMake(widthInPoints, heightInPoints));
    }
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    return image;
}


-(BOOL)captureToPhotoAlbumNew:(UIImageView *)imageView
{
    UIImage *image = imageView.image;//修改方式
    
    NSDate *senddate=[NSDate date];
    
    //创建一个目录  //shoto
    NSString *strDir = [kLibraryPath stringByAppendingPathComponent:@"shoto"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:strDir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDir withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDir] setResourceValue: [NSNumber numberWithBool: YES]
                                                  forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd"];
    //每天的记录创建一个
    NSString *strDirYear = [strDir stringByAppendingPathComponent:[fileformatter stringFromDate:senddate]];
    [fileformatter setDateFormat:@"YYYYMMddHHmmss"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:strDirYear]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:strDirYear withIntermediateDirectories:NO attributes:nil error:nil];
        [[NSURL fileURLWithPath:strDirYear] setResourceValue: [NSNumber numberWithBool: YES]
                                                      forKey: NSURLIsExcludedFromBackupKey error:nil];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[fileformatter stringFromDate:senddate]];
    NSString *strPath = [strDirYear stringByAppendingPathComponent:fileName];
    
    BOOL result = [UIImageJPEGRepresentation(image,0.8f) writeToFile:strPath atomically:YES];
    
    BOOL success = [[NSURL fileURLWithPath:strPath] setResourceValue: [NSNumber numberWithBool: YES]
                                                              forKey: NSURLIsExcludedFromBackupKey error:nil];
    if (result&&success)
    {
        DLog(@"抓拍");
        return  YES;
    }
    else
    {
        return NO;
    }
}
-(void)switchVideoCodeInfo:(id)sender
{
    PlayControllerView *playView = [_array objectAtIndex:nIndex];
    if (playView.bPlay)
    {
        PlayControlModel *playModel = [_decoderInfo objectForKey:playView.strKey];
        if (playModel)
        {
            playModel.decode.playing = NO;
            [playModel.decode switchP2PCode:2];
        }
    }
}
@end
