//
//  UpdRealViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/11.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "UpdRealViewController.h"
#import "CustomNaviBarView.h"
#import "UpdRealService.h"
#import "ProgressHUD.h"
#import "Toast+UIView.h"

#import "XCNotification.h"
@interface UpdRealViewController ()

@property (nonatomic,strong) UITextField *txtRealName;
@property (nonatomic,strong) UpdRealService *updServer;
@end

@implementation UpdRealViewController
-(void)initHeadView
{
    
    [self setNaviBarTitle:XCLocalized(@"updateReal")];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    UIButton *right = [CustomNaviBarView createNormalNaviBarBtnByTitle:XCLocalized(@"save") target:self action:@selector(updateRealName)];
    [self setNaviBarRightBtn:right];
    
}

-(void)updateRealName
{
    [_txtRealName resignFirstResponder];
    NSString *strEmail = [_txtRealName text];
    if ([strEmail isEqualToString:@""])
    {
        [self.view makeToast:XCLocalized(@"nickEmpty")];
        return;
    }
    if ([strEmail length]>kUSER_INFO_MAX_LENGTH) {
        [self.view makeToast:XCLocalized(@"realThan64")];
        return ;
    }
    
    if (_updServer)
    {
        __weak UpdRealViewController *__weakSelf = self;
        _updServer.httpBlock = ^(int nStatus)
        {
            dispatch_async(dispatch_get_main_queue(), ^{[ProgressHUD dismiss];});
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
        [_updServer requestUpdReal:strEmail];
    }
}

-(void)navBack
{
 
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initHeadView];
    _txtRealName = [[UITextField alloc] initWithFrame:Rect(0, [CustomNaviBarView barSize].height+20, kScreenWidth, 39.5)];
    [self.view addSubview:_txtRealName];
    [_txtRealName setBorderStyle:UITextBorderStyleNone];
    [self.view setBackgroundColor:RGB(247, 247, 247)];
    UIImageView *imgPwd = [[UIImageView alloc] init];
    imgPwd.frame = Rect(0, 0, 20, 39.5);
    _txtRealName.leftView = imgPwd;
    _txtRealName.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _txtRealName.leftViewMode = UITextFieldViewModeAlways;
    UIColor *color = [UIColor grayColor];
    _txtRealName.attributedPlaceholder = [[NSAttributedString alloc] initWithString:XCLocalized(@"RealName") attributes:@{NSForegroundColorAttributeName: color}];
    [_txtRealName setReturnKeyType:UIReturnKeyDone];
    [_txtRealName setBackgroundColor:[UIColor whiteColor]];
    _updServer = [[UpdRealService alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark 重力处理
- (BOOL)shouldAutorotate
{
    return NO;
}
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


-(void)closeKeyBoard
{
    [_txtRealName resignFirstResponder];
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
