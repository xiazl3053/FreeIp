//
//  PlayViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/10.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "PlayViewController.h"
#import "DecoderPublic.h"
#import "UIView+Extension.h"
#import "UtilsMacro.h"
@interface PlayViewController ()

{
    CGFloat lastX,lastY,lastScale;
    CGFloat fWidth,fHeight;
}

@property (nonatomic,copy) NSString *strNO;
@property (nonatomic,copy) NSString *strName;

@end

@implementation PlayViewController

-(id)initWithNO:(NSString *)nsNO name:(NSString *)strName format:(NSUInteger)nFormat
{
    self = [super init];
    _strNO = nsNO;
    _strName = strName;
    _decodeImpl = [[XLDecoderServiceImpl alloc] init];
    if (!IOS_SYSTEM_8)
    {
        fWidth = kScreenWidth;
        fHeight = kScreenHeight;
    }
    else
    {
        fWidth = kScreenSourchHeight;
        fHeight = kScreenSourchWidth;
    }
    return self;
}

-(void)hudViewCreate
{
    _topHUD = [[VideoTopHud alloc] initWithFrame:Rect(0, 0, kScreenWidth, 49)];
    _downHUD = [[VideoDownHud alloc] initWithFrame:Rect(0, kScreenSourchHeight-50, kScreenWidth, 50)];
    _topHUD.lblName.text = _strName;
    [self.view addSubview:_topHUD];
    [self.view addSubview:_downHUD];
    
    _imgView = [[UIImageView alloc] initWithFrame:Rect(0, 0, kScreenWidth, kScreenSourchHeight)];
    [self.view insertSubview:_imgView atIndex:0];
    
    _imgView.contentMode = UIViewContentModeScaleToFill;//UIViewContentModeScaleAspectFill;UIViewContentModeScaleAspectFit
    _imgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [_imgView setUserInteractionEnabled:YES];
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchEvent:)];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
    [_imgView addGestureRecognizer:panGesture];
    [_imgView addGestureRecognizer:pinchGesture];
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
    CGFloat frameX = (_imgView.x + (curPoint.x-lastX)) > 0 ? 0 : (fabs(_imgView.x+(curPoint.x-lastX))+fWidth >= _imgView.width ? -(_imgView.width-fWidth) : (_imgView.x+(curPoint.x-lastX)));
    CGFloat frameY =(_imgView.y + (curPoint.y-lastY))>0?0: (fabs(_imgView.y+(curPoint.y-lastY))+fHeight >= _imgView.height ? -(_imgView.height-fHeight) : (_imgView.y+(curPoint.y-lastY)));
    _imgView.frame = Rect(frameX,frameY , _imgView.width, _imgView.height);
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
    CGFloat glWidth = _imgView.frame.size.width;
    CGFloat glHeight = _imgView.frame.size.height;
    CGFloat fScale = [sender scale];
    
    if (_imgView.frame.size.width * [sender scale] <= fWidth)
    {
        lastScale = 1.0f;
        _imgView.frame = Rect(0, 0, fWidth, fHeight);
    }
    else
    {
        lastScale = 1.5f;
        CGPoint point = [sender locationInView:self.view];
        DLog(@"point:%f--%f",point.x,point.y);
        CGFloat nowWidth = glWidth*fScale>fWidth*4?fWidth*4:glWidth*fScale;
        CGFloat nowHeight =glHeight*fScale >fHeight* 4?fHeight*4:glHeight*fScale;
        _imgView.frame = Rect(fWidth/2 - nowWidth/2,fHeight/2- nowHeight/2,nowWidth,nowHeight);
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self hudViewCreate];
    _videoFrame = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)startPlay
{
      if(_bPlaying)
      {
          if(_videoFrame.count>0)
          {
              [self updatePlayUI];
              
          }
          if (_videoFrame.count==0)
          {
              //解码开启
              [self decodeAsync];
          }
          __weak PlayViewController *__weakSelf = self;
          dispatch_time_t after = dispatch_time(DISPATCH_TIME_NOW, 0.025 * NSEC_PER_SEC );
          dispatch_after(after, dispatch_get_global_queue(0, 0),
          ^{
              [__weakSelf startPlay];
          });
      }
}

-(CGFloat)updatePlayUI
{
    CGFloat interval = 0;
    KxVideoFrame *frame;
    @synchronized(_videoFrame)
    {
        if (_videoFrame.count > 0)
        {
            frame = _videoFrame[0];
            [_videoFrame removeObjectAtIndex:0];
        }
    }
    if (frame)
    {
        __weak PlayViewController *__weakSelf = self;
        KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB*)frame;
        __weak KxVideoFrameRGB *__rgbFrame = rgbFrame;
        dispatch_sync(dispatch_get_main_queue(),
        ^{
            [__weakSelf.imgView setImage:[__rgbFrame asImage]];
        });
        rgbFrame = nil;
        interval = frame.duration;
        frame = nil;
        
    }
    return interval;
}



-(void)decodeAsync
{
    if (!_bPlaying || _bDecoding)
    {
        return ;
    }
    _bDecoding = YES;
    __weak PlayViewController *__weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL bGood = YES;
        while (bGood)
        {
            NSArray *array = [__weakSelf.decodeImpl decodeFrame];
            bGood = NO;
            if (array && array.count>0)
            {
                @synchronized(__weakSelf.videoFrame)
                {
                    for (KxVideoFrame *frame in array)
                    {
                        [__weakSelf.videoFrame addObject:frame];
                    }
                }
            }
        }
        __weakSelf.bDecoding = NO;
    });
}

-(void)dealloc
{
    DLog(@"GG VIEW");
    _bPlaying = NO;
    _bDecoding = NO;
    _imgView = nil;
    _decodeImpl = nil;
    @synchronized(_videoFrame)
    {
        [_videoFrame removeAllObjects];
    }
    _videoFrame = nil;
}

@end
