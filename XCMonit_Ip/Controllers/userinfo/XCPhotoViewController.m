//
//  XCPhotoViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/2/6.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "XCPhotoViewController.h"
#import "XCPhoto.h"
#import "XCNotification.h"
#import "PhoneDb.h"
#import "XCPhotoToolBar.h"

@interface XCPhotoViewController ()<UIScrollViewDelegate>
{
    UIScrollView *_scrollView;
    UIImageView *_imgView;
    CGFloat initialZoom;
    // 工具条
    XCPhotoToolbar *_toolbar;
}

@property (nonatomic,strong) NSMutableArray *aryPhoto;
@property (nonatomic,assign) int nIndex;


@end

@implementation XCPhotoViewController

-(void)show
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self.view];
    [window.rootViewController addChildViewController:self];
}

-(id)initWithArray:(NSMutableArray*)ary current:(int)nSelect
{
    self = [super init];
    if (self)
    {
        _aryPhoto = ary;
        _nIndex = nSelect;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    CGRect frame = self.view.bounds;
    
    DLog(@"frame:%@",NSStringFromCGRect(frame));
    
    _scrollView = [[UIScrollView alloc] initWithFrame:frame];
    
    _imgView = [[UIImageView alloc] initWithFrame:_scrollView.bounds];
    [self.view addSubview:_scrollView];
    [_scrollView addSubview:_imgView];
    
    _imgView.contentMode = UIViewContentModeScaleAspectFill ;
    
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = YES;
    _scrollView.showsVerticalScrollIndicator = YES;
    
    [self setImage];
    
    UISwipeGestureRecognizer *recognizerRight;
    
    recognizerRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    
    [recognizerRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:recognizerRight];
    
    UISwipeGestureRecognizer *recognizerLeft;
    recognizerLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizerLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:recognizerLeft];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeView)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    [recognizerLeft requireGestureRecognizerToFail:tap];
    [recognizerRight requireGestureRecognizerToFail:tap];
    
    [self.view setUserInteractionEnabled:YES];
    [self createToolbar];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeImageInfo) name:NS_DELETE_IMAGE_VC object:nil];
}

-(void)removeImageInfo
{
    DLog(@"11111");
    //先删除
    if (_nIndex >= _aryPhoto.count || _nIndex <0)
    {
        return ;
    }
    XCPhoto *photo = [_aryPhoto objectAtIndex:_nIndex];
    
    [PhoneDb deleteRecordById:photo.nId];
    
    [[NSFileManager defaultManager] removeItemAtPath:photo.strPath error:nil];
    
    [_aryPhoto removeObject:photo];
    
    if (_aryPhoto.count == 0)
    {
        [self closeView];
        return ;
    }
    
    if(_nIndex == _aryPhoto.count)
    {
        _nIndex--;
    }
    __weak XCPhotoViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__self setImage];
    });
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

- (void)createToolbar
{
    CGFloat barHeight = 44;
    CGFloat barY = self.view.frame.size.height - barHeight;
    _toolbar = [[XCPhotoToolbar alloc] init];
    _toolbar.frame = CGRectMake(0, barY, self.view.frame.size.width, barHeight);
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _toolbar.photos = _aryPhoto;
    [self.view addSubview:_toolbar];
    [self updateTollbarState];
}

#pragma mark 更新toolbar状态
- (void)updateTollbarState
{
    _toolbar.currentPhotoIndex = _nIndex;
}

-(void)closeView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_UPDATE_IMAGE_VC object:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

-(void)setImage
{
    XCPhoto *photo= [_aryPhoto objectAtIndex:_nIndex];
    
    CGFloat fHeight = _scrollView.frame.size.width/photo.imgName.size.width*photo.imgName.size.height;
    CGFloat origin_y = (_scrollView.frame.size.height - fHeight)/2;

    _imgView.frame = CGRectMake(0, origin_y, _scrollView.frame.size.width, fHeight);
    
    initialZoom = 1;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0f];
    [_imgView setImage:photo.imgName];
    
    [_scrollView setZoomScale:1];
    [_scrollView setMinimumZoomScale:1];
    [_scrollView setMaximumZoomScale:2];
    
    [UIView commitAnimations];
        
    [self updateTollbarState];
    
}

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer
{
    
    if(recognizer.direction==UISwipeGestureRecognizerDirectionDown) {
        //执行程序
    }
    if(recognizer.direction==UISwipeGestureRecognizerDirectionUp) {
        

        //执行程序
    }
    
    if(recognizer.direction==UISwipeGestureRecognizerDirectionLeft)
    {
        //++
        if (_nIndex+1 != _aryPhoto.count )
        {
            _nIndex++;
            [self setImage];
        }
    }
    if(recognizer.direction==UISwipeGestureRecognizerDirectionRight)
    {
        //--
        if (_nIndex > 0)
        {
            _nIndex--;
            [self setImage];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}


-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationPortrait;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imgView;
    
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
     _imgView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                  scrollView.contentSize.height * 0.5 + offsetY);
}

@end
