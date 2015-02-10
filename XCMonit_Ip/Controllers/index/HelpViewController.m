//
//  HelpViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/11/4.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "HelpViewController.h"
#import "CustomNaviBarView.h"


@interface HelpViewController ()
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) UIScrollView *scrollView;
@end

@implementation HelpViewController

-(void)dealloc
{
    _imgView.image = nil;
    [_imgView removeFromSuperview];
    _imgView = nil;
    [_scrollView removeFromSuperview];
    _scrollView = nil;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNaviBarTitle:XCLocalized(@"help")];
    [self setNaviBarRightBtn:nil];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back_H"] forState:UIControlStateHighlighted];
    [btn addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarLeftBtn:btn];
    CGRect frame ;
    if (isPhone6p)
    {
        frame.size.height = 460;
    }
    else
    {
        frame.size.height = 355;
    }

    _scrollView = [[UIScrollView alloc] initWithFrame:Rect(0,[CustomNaviBarView barSize].height,kScreenWidth,kScreenHeight - [CustomNaviBarView barSize].height+HEIGHT_MENU_VIEW(20, 0))];
                                                           
    [self.view addSubview:_scrollView];
    
    [self.view setBackgroundColor:RGB(244, 244, 244)];

    frame.size.width = kScreenWidth;
    frame.origin.x = 0;
    frame.origin.y = 0;
    
    _imgView = [[UIImageView alloc] initWithFrame:Rect(0, 0, kScreenWidth, frame.size.height*5)];
    [_imgView setImage:[UIImage imageNamed:XCLocalized(@"helpicon")]];
    [_scrollView addSubview:_imgView];
    _scrollView.contentSize = CGSizeMake(kScreenWidth,frame.size.height*5);
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark 重力处理
- (BOOL)shouldAutorotate NS_AVAILABLE_IOS(6_0)
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
