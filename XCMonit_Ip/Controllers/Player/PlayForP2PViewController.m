//
//  PlayForP2PVewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/16.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "PlayForP2PViewController.h"
#import "PTPSource.h"
#import "UtilsMacro.h"
#import "UIControl+BlocksKit.h"
#import "ProgressHUD.h"
#import "XCNotification.h"

#import "XLDecoder.h"
#import "Toast+UIView.h"
#import "PTZView.h"
@interface PlayForP2PViewController()<PTZViewDelegate>
{
    CGFloat fWidth;
    CGFloat fHeight;
    int nCodeType;
    XLDecoder *_decoder;
}
@property (nonatomic,strong) NSString *strNO;
@property (nonatomic,strong) PTPSource *ptpSource;
@property (nonatomic,strong) PTZView *ptzView;


@end
@implementation PlayForP2PViewController

-(id)initWithNO:(NSString *)nsNO name:(NSString *)strName format:(NSUInteger)nFormat
{
    self = [super initWithNO:nsNO name:strName format:nFormat];
    nCodeType = 1;
    _ptpSource = [[PTPSource alloc] initWithNO:nsNO channel:0 codeType:nCodeType];
    _strNO = nsNO;
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.imgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapEvent:)]];
    
    _ptzView = [[PTZView alloc] initWithFrame:Rect(0, 0, 164, 114)];
    [self.view addSubview:_ptzView];
    _ptzView.hidden = YES;
    _ptzView.delegate = self;
}

-(void)tapEvent:(UITapGestureRecognizer*)sender
{
    CGPoint location = [sender locationInView:self.view];
    if (location.y<49) {
        return ;
    }
    self.topHUD.hidden = !self.topHUD.hidden;
    self.downHUD.hidden = self.topHUD.hidden;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self playLayout];
    //P2P打洞
    [self P2PInitConnection];
}

-(void)P2PInitConnection
{
    __weak PlayForP2PViewController *__weakSelf = self;
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
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [ProgressHUD showPlayRight:XCLocalized(@"loading") viewInfo:__weakSelf.view];
        });
    }
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
          [__weakSelf initDecodeInfo];
    });
}

-(void)initDecodeInfo
{
    BOOL bFlag = [self.decodeImpl connection:_ptpSource];
    __weak PlayForP2PViewController *__weakSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [ProgressHUD dismiss];
    });
    if (bFlag)
    {
        DLog(@"连接成功?");
        _decoder = [[XLDecoder alloc] initWithDecodeSource:_ptpSource];
        self.bPlaying= YES;
        [self.decodeImpl decoder_init:_decoder];
        [self startPlay];
    }
    else
    {
        DLog(@"连接失败");
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__weakSelf.view makeToast:@"连接失败"];
        });
    }
}

#pragma mark 旋转之后的第一次界面显示
-(void)playLayout
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
    self.topHUD.frame = Rect(0, 0, fWidth, 49);
    [self.topHUD viewWithTag:10001].frame = self.topHUD.bounds;
    
    self.downHUD.frame = Rect(0, fHeight-50, fWidth, 50);
    self.topHUD.lblName.frame = Rect(50, 15, 200,20);
    [self.topHUD.lblName setTextColor:[UIColor whiteColor]];
    [self.topHUD.lblName setTextAlignment:NSTextAlignmentLeft];
    //横屏的时候修改变更内容
    [self.downHUD.playbtn setFrame:Rect(fWidth-60*3, 1,60, 48)];
    [self.downHUD.recordBtn setFrame:Rect(fWidth-60, 1, 60, 48)];
    [self.downHUD.captureBtn setFrame:Rect(fWidth-120, 1, 60, 48)];
    __weak PlayForP2PViewController *__weakSelf = self;
    
    [self.topHUD.doneButton bk_addEventHandler:^(id sender){
        [__weakSelf goBack];
    } forControlEvents:UIControlEventTouchUpInside];

    [self.downHUD.playbtn bk_addEventHandler:^(id sender){
        [__weakSelf playAction:sender];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [self.downHUD.recordBtn bk_addEventHandler:^(id sender){
        [__weakSelf recordOper:sender];
    } forControlEvents:UIControlEventTouchUpInside];
    [self.downHUD.captureBtn bk_addEventHandler:^(id sender){
        [__weakSelf captureOper:sender];
    }
    forControlEvents:UIControlEventTouchUpInside];
    self.imgView.frame = Rect(0, 0, fWidth, fHeight);
    
    _ptzView.frame  = Rect(fWidth-164, fHeight/2-57, 164, 114);
    [self.topHUD addPtz];
    [self.topHUD addSwtich];
    
    self.topHUD.btnBD.frame = Rect(fWidth-180, 0, 60, 48);
    self.topHUD.btnHD.frame = Rect(fWidth-120, 0, 60, 48);
    self.topHUD.btnPtzView.frame = Rect(fWidth-60, 0, 60, 48);
    
    [self.topHUD.btnBD bk_addEventHandler:^(id sender)
    {
        [__weakSelf switchVideo:sender];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [self.topHUD.btnHD bk_addEventHandler:^(id sender)
    {
        [__weakSelf switchVideo:sender];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [self.topHUD.btnPtzView bk_addEventHandler:^(id sender)
    {
        [__weakSelf ptzShowOrHidden];
    } forControlEvents:UIControlEventTouchUpInside];
    
}


-(void)ptzShowOrHidden
{
    _ptzView.hidden = !_ptzView.hidden;
}


-(void)switchVideo:(UIButton*)sender
{
    int nDest = 0;
    if (sender.tag == 10002)
    {
        nDest = 2;
    }
    else
    {
        nDest = 1;
    }
    nCodeType = nDest;
    __block int __nCode = nDest;
    __weak PlayForP2PViewController *__weakSelf = self;
    if([_ptpSource getSource]==1)//P2P
    {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0),
            ^{
                   if (__weakSelf.ptpSource)
                   {
                       [__weakSelf.ptpSource switchP2PCode:__nCode];
                   }
                   while (!__weakSelf.ptpSource.nSwitchcode)
                   {
                       [NSThread sleepForTimeInterval:0.1f];
                   }
                   __weakSelf.bPlaying = YES;
                   [__weakSelf startPlay];
                   @synchronized(__weakSelf.videoFrame)
                   {
                       [__weakSelf.videoFrame removeAllObjects];
                   }
            });
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reTran) name:NS_SWITCH_TRAN_OPEN_VC object:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [__weakSelf stopVideo];
        });
    }

}

-(void)releaseP2PView
{
    [_decoder stopDecode];
    self.bPlaying = NO;
    [_ptpSource releaseDecode];
    self.imgView.image = nil;
}

-(void)stopVideo
{
    DLog(@"视频停止");
    self.bPlaying = NO;
    [_ptpSource releaseDecode];
    _ptpSource = nil;
    __weak PlayForP2PViewController *__weakSelf = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__weakSelf.imgView setImage:nil];
    });
}

-(void)reTran
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NS_SWITCH_TRAN_OPEN_VC object:nil];
    PTPSource *ptpSrc = [[PTPSource alloc]initWithNO:_strNO channel:0 codeType:nCodeType];
    __weak PlayForP2PViewController *__weakSelf = self;
    __weak PTPSource *__weakPtp = ptpSrc;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        BOOL bFalg = [__weakSelf.decodeImpl connection:__weakPtp];
        if (bFalg)
        {
            __weakSelf.bPlaying = YES;
            [__weakSelf startPlay];
            __weakSelf.ptpSource = __weakPtp;
        }
    });
}

-(void)recordOper:(UIButton*)sender
{
    DLog(@"record");
}

-(void)captureOper:(UIButton*)sender
{
    DLog(@"captureOper");
}

-(void)playAction:(UIButton *)sender
{
    DLog(@"player");
}


-(void)goBack
{
    self.bPlaying = NO;
    __weak PlayForP2PViewController *__weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [__weakSelf releaseP2PView];
        });
    }];
}


#pragma mark 数据
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

-(BOOL)shouldAutorotate
{
    return NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectFail:) name:NSCONNECT_P2P_FAIL_VC object:nil];
}

-(void)connectFail:(NSNotification*)notify
{
    DLog(@"notify:%@",[notify object]);
    __weak PlayForP2PViewController *__weakSelf =self ;
    dispatch_async(dispatch_get_global_queue(0,0),
    ^{
        [__weakSelf stopVideo];
    });
    __weak NSString *strInfo = [notify object];
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__weakSelf.view makeToast:strInfo];
    });
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.topHUD.btnBD bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    [self.topHUD.btnHD bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    [self.topHUD.btnPtzView bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    [self.downHUD.playbtn bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    [self.downHUD.recordBtn bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    [self.downHUD.captureBtn bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    DLog(@"删除通知");
}

-(void)dealloc
{
    DLog(@"GG");
    _ptpSource = nil;
    _decoder = nil;
    _strNO = nil;
}

@end
