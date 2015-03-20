//
//  UpdNikNameViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/11.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "UpdNikNameViewController.h"
#import "CustomNaviBarView.h"
#import "UpdNickService.h"
#import "Toast+UIView.h"
#import "ProgressHUD.h"
#import "XCNotification.h"

@interface UpdNikNameViewController ()

@property (nonatomic,strong) UITextField *txtNick;
@property (nonatomic,strong) UpdNickService *updServer;

@end

@implementation UpdNikNameViewController
-(void)initHeadView
{
    
    [self setNaviBarTitle:XCLocalized(@"nickUpd")];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    UIButton *right = [CustomNaviBarView createNormalNaviBarBtnByTitle:XCLocalized(@"save") target:self action:@selector(updateNickName)];
    [self setNaviBarRightBtn:right];
    
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)updateNickName
{
    [_txtNick resignFirstResponder];
    NSString *strEmail = [_txtNick text];
    if ([strEmail isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"realEmpty")];
        return;
    }
    
    if ([strEmail length]>kUSER_INFO_MAX_LENGTH)
    {
        [self.view makeToast:XCLocalized(@"nickThan64")];
        return ;
    }
    
    if (_updServer)
    {
        __weak UpdNikNameViewController *__weakSelf = self;
        _updServer.httpBlock = ^(int nStatus)
        {
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [ProgressHUD dismiss];
            });
            switch (nStatus) {
                case 1:
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:NS_UPDATE_USER_INFO_VC object:nil];
                    [__weakSelf.view makeToast:XCLocalized(@"updateOK")];
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.6 * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                   {
                       [__weakSelf navBack];
                   });
                }
                break;
                default:
                {
                    [__weakSelf.view makeToast:XCLocalized(@"deleteDeviceFail_server")];
                }
                break;
            }
        };
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [ProgressHUD show:XCLocalized(@"updnicking")];
        });
        [_updServer requestUpdNick:strEmail];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initHeadView];
    _txtNick = [[UITextField alloc] initWithFrame:Rect(0, [CustomNaviBarView barSize].height+20, kScreenWidth, 39.5)];
    [self.view addSubview:_txtNick];
    [_txtNick setBorderStyle:UITextBorderStyleNone];
    [self.view setBackgroundColor:RGB(247, 247, 247)];
    UIImageView *imgPwd = [[UIImageView alloc] init];
    imgPwd.frame = Rect(0, 0, 20, 39.5);
    _txtNick.leftView = imgPwd;
    _txtNick.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtNick.leftViewMode = UITextFieldViewModeAlways;
    UIColor *color = [UIColor grayColor];
    _txtNick.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"Nickname") attributes:@{NSForegroundColorAttributeName: color}];
    [_txtNick setReturnKeyType:UIReturnKeyDone];
    [_txtNick setBackgroundColor:[UIColor whiteColor]];
    _updServer = [[UpdNickService alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)closeKeyBoard
{
    [_txtNick resignFirstResponder];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeKeyBoard) name:NSKEY_BOARD_RETURN_VC object:nil];
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
