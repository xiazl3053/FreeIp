//
//  VersionInfoViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/20.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "VersionInfoViewController.h"
#import "CustomNaviBarView.h"
@interface VersionInfoViewController ()

@end

@implementation VersionInfoViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)initUI
{
    [self setNaviBarTitle:NSLocalizedString(@"versionInfo", "versionInfo")];    // 设置标题
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];       // 若不需要默认的返回按钮，直接赋nil
    [self setNaviBarRightBtn:nil];
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
