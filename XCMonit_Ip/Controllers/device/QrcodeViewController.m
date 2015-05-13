//
//  QrcodeViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/9.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "QrcodeViewController.h"
#import "CustomNaviBarView.h"
#import "AddDevViewController.h"
#import "Toast+UIView.h"
@interface QrcodeViewController()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    int num;
    BOOL upOrdown;
    NSTimer * timer;
    UIButton *btnPhoto;
}
@property (nonatomic, strong) UIImageView * line;
@property (nonatomic, strong) ZBarReaderView *readerView;
@property (nonatomic,strong) UIImagePickerController *imagePicker;

@end

@implementation QrcodeViewController

-(void)dealloc
{
    [_readerView removeFromSuperview];
    [_line removeFromSuperview];
    _readerView = nil;
    _line = nil;
    [_imagePicker removeFromParentViewController];
    _imagePicker = nil;
    [timer invalidate];
    timer = nil;
    [btnPhoto removeFromSuperview];
    btnPhoto = nil;
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

-(void)enterAddDev
{
    AddDevViewController *addDev = [[AddDevViewController alloc] init];
    [self presentViewController:addDev animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNaviBarTitle:XCLocalized(@"devDetails")];
    
    UIButton *rightBtn = [CustomNaviBarView createNormalNaviBarBtnByTitle:XCLocalized(@"input")
                    target:self action:@selector(enterAddDev)];//scanQRCode   enterAddDev
    [self setNaviBarRightBtn:rightBtn];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_H" target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    
    _readerView = [[ZBarReaderView alloc] init];
    _readerView.frame = Rect(0, [CustomNaviBarView barSize].height, kScreenWidth, kScreenHeight-[CustomNaviBarView barSize].height+HEIGHT_MENU_VIEW(20, 0));
    self.readerView.readerDelegate = self;
    [self.readerView setAllowsPinchZoom:YES];
    [self.view addSubview:_readerView];

    ZBarImageScanner * scanner = _readerView.scanner;
    [scanner setSymbology:ZBAR_I25
                   config:ZBAR_CFG_ENABLE
                       to:0];
    
    _readerView.torchMode = 0;
    
    UIView *view = [[UIView alloc] initWithFrame:Rect(0, 0,kScreenWidth, self.readerView.frame.size.height/2.0-130)];
    [view setBackgroundColor:[UIColor blackColor]];
    [_readerView addSubview:view];
    view.alpha = 0.6f;
    
    UIView *view1 = [[UIView alloc] initWithFrame:Rect(0, self.readerView.frame.size.height/2.0-130,30, 260)];
    [view1 setBackgroundColor:[UIColor blackColor]];
    [_readerView addSubview:view1];
    view1.alpha = 0.6f;
    
    UIView *view2 = [[UIView alloc] initWithFrame:Rect(kScreenWidth-30, self.readerView.frame.size.height/2.0-130,60, 260)];
    [view2 setBackgroundColor:[UIColor blackColor]];
    [_readerView addSubview:view2];
    view2.alpha = 0.6f;
    
    UIView *view3 = [[UIView alloc] initWithFrame:Rect(0,self.readerView.frame.size.height/2.0+130,kScreenWidth,self.readerView.frame.size.height-self.readerView.frame.size.height/2.0+100)];
    [view3 setBackgroundColor:[UIColor blackColor]];
    [_readerView addSubview:view3];
    view3.alpha = 0.6f;
    
    
    CGRect scanMaskRect = CGRectMake(30, self.readerView.frame.size.height/2.0-130, kScreenWidth-60, 260);
    CGRect newRect = [self getScanCrop:scanMaskRect readerViewBounds:_readerView.bounds];
    DLog(@"newRect:%@",NSStringFromCGRect(newRect));
    _readerView.scanCrop = newRect;
    UIImageView * image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pick_bg.png"]];
    image.frame = scanMaskRect;
    
    [_readerView addSubview:image];
    
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(20, 10, scanMaskRect.size.width-20, 2)];
    _line.image = [UIImage imageNamed:@"line.png"];
    [image addSubview:_line];
 //   定时器，设定时间过1.5秒，
    timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation1) userInfo:nil repeats:YES];
    
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    _imagePicker.delegate = self;
    _imagePicker.allowsEditing = NO;
    
    btnPhoto = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnPhoto setImage:[UIImage imageNamed:XCLocalized(@"qrcode")] forState:UIControlStateNormal];
    [btnPhoto setImage:[UIImage imageNamed:XCLocalized(@"qrcode_h")] forState:UIControlStateHighlighted];
    [self.view addSubview:btnPhoto];
    btnPhoto.frame = Rect(kScreenWidth/2-112.5,self.readerView.frame.origin.y + self.readerView.frame.size.height/2.0+145 ,225.5,75.5);
    [btnPhoto addTarget:self action:@selector(scanQRCode) forControlEvents:UIControlEventTouchUpInside];
    
}
-(void)animation1
{
    if (upOrdown == NO)
    {
        num ++;
        _line.frame = CGRectMake(10, 10+2*num, _line.frame.size.width, 2);
        if (2*num == 240)
        {
            upOrdown = YES;
        }
    }
    else
    {
        num --;
        _line.frame = CGRectMake(10, 10+2*num, _line.frame.size.width, 2);
        if (num == 0)
        {
            upOrdown = NO;
        }
    }
}

-(CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)readerViewBounds
{
    CGFloat x,y,width,height;
    
    x = rect.origin.x / readerViewBounds.size.width;
    y = rect.origin.y / readerViewBounds.size.height;
    width = rect.size.width / readerViewBounds.size.width;
    height = rect.size.height / readerViewBounds.size.height;
    return CGRectMake(x, y, width, height);
}
- (NSString *)findQRCode:(UIImage *)inputUIImage
{
    
    ZBarReaderController *imageReader = [ZBarReaderController new];
    
    [imageReader.scanner setSymbology: ZBAR_I25
                               config: ZBAR_CFG_ENABLE
                                   to: 0];
    
    id <NSFastEnumeration> results = [imageReader scanImage:inputUIImage.CGImage];
    
    ZBarSymbol *sym = nil;
    for(sym in results) {
        break;
    } // Get only last symbol
    
    if (!sym)
    {
        [self.view makeToast:XCLocalized(@"qrResult")];
        return nil;
    }
    AddDevViewController *addDev = [[AddDevViewController alloc] init];
    __weak AddDevViewController *__addDev = addDev;
    __block NSString *__strInfo = sym.data;
    [self presentViewController:addDev animated:YES completion:
     ^{
         [__addDev authNO:__strInfo];
     }];

    return sym.data;
}

-(void)scanQRCode
{
    [self presentViewController:_imagePicker animated:YES completion:^{}];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* image = nil;
    image = [info objectForKey: @"UIImagePickerControllerOriginalImage"];
    [self dismissViewControllerAnimated:YES completion:^{}];
    [self findQRCode:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}



-(void)readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image
{
    NSString *codeData = [[NSString alloc] init];;
    for (ZBarSymbol *sym in symbols) {
        codeData = [[sym.data stringByReplacingOccurrencesOfString:@"\r" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        break;
    }
    AddDevViewController *addDev = [[AddDevViewController alloc] init];
    __weak AddDevViewController *__addDev = addDev;
    __block NSString *__strInfo = [codeData stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self presentViewController:addDev animated:YES completion:
    ^{
          [__addDev authNO:__strInfo];
    }];
    DLog(@"%@", codeData);
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.readerView start];
    DLog(@"start");
}
-(void)viewDidDisappear:(BOOL)animated
{
    [self.readerView stop];
}



#pragma mark 重力处理
- (BOOL)shouldAutorotate
{
    return NO;
}
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
