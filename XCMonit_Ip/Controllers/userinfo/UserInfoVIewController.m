//
//  UserInfoVIewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "UserInfoVIewController.h"
#import "UserInfoService.h"
#import "CustomNaviBarView.h"
#import "DeviceInfoCell.h"
#import "UserImageCell.h"
#import "UserInfo.h"
#import "Toast+UIView.h"
#import "UpdEmailViewController.h"
#import "UpdPwdViewController.h"
#import "UpdNikNameViewController.h"
#import "UpdRealViewController.h"
#import "XCNotification.h"
#import "RSKImageCropper.h"
#import "UserInfoCell.h"
#import "UploadImageService.h"

#define USER_INFO_NULL NSLocalizedString(@"NULLInfo", nil)

//修改昵称、邮箱、密码、
@interface UserInfoVIewController ()<UITableViewDelegate,UITableViewDataSource,RSKImageCropViewControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    BOOL bView;
}

@property (nonatomic,strong) UIView *hiddenView;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UserAllInfoModel *userAll;
@property (nonatomic,strong) UserInfoService *userServie;
@property (nonatomic,strong) UIImagePickerController *imagePicker;
@property (nonatomic,strong) UIImagePickerController *camrePicker;
@property (nonatomic,strong) UploadImageService *upload;

@end

@implementation UserInfoVIewController

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
    [self setNaviBarTitle:XCLocalized(@"userinfo")];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth, kScreenHeight -[CustomNaviBarView barSize].height+HEIGHT_MENU_VIEW(20, 0)) style:UITableViewStyleGrouped];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    bView = YES;
    [self initData];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview: btn];
    [btn setTitle:XCLocalized(@"updpwd") forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"delete_btn"] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"delete_btn_onpress"] forState:UIControlStateHighlighted];
    btn.frame = Rect(kScreenWidth/2.0-276/2,[CustomNaviBarView barSize].height+149+44.5*4+20 , 276, 43);
    [btn addTarget:self action:@selector(updatePwd) forControlEvents:UIControlEventTouchUpInside];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initData) name:NS_UPDATE_USER_INFO_VC object:nil];//:NS_UPDATE_USER_INFO_VC object:nil];
    [self initHiddenView];
    _upload = [[UploadImageService alloc] init];;
}

-(void)initHiddenView
{
    _hiddenView = [[UIView alloc] initWithFrame:Rect(0, kScreenHeight-200,kScreenWidth,200+HEIGHT_MENU_VIEW(20, 0))];
    _hiddenView.backgroundColor = RGB(240, 240, 240);
    [self.view addSubview:_hiddenView];
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *btn3 = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn1 setTitle:XCLocalized(@"photos") forState:UIControlStateNormal];
    [btn2 setTitle:XCLocalized(@"camera") forState:UIControlStateNormal];
    [btn3 setTitle:XCLocalized(@"cancel") forState:UIControlStateNormal];
    [btn1 setTitleColor:RGB(26,26, 26) forState:UIControlStateNormal];
    [btn3 setTitleColor:RGB(26,26, 26) forState:UIControlStateNormal];
    [btn2 setTitleColor:RGB(26,26, 26) forState:UIControlStateNormal];
    
    btn1.layer.borderWidth = 0.5;
    btn2.layer.borderWidth = 0.5;
    btn3.layer.borderWidth = 0.5;
    btn1.layer.borderColor = (RGB(178, 178, 178)).CGColor;
    btn2.layer.borderColor = (RGB(178, 178, 178)).CGColor;
    btn3.layer.borderColor = (RGB(178, 178, 178)).CGColor;
    btn1.layer.MasksToBounds = YES;
    btn1.layer.cornerRadius = 2.0f;
    btn2.layer.MasksToBounds = YES;
    btn2.layer.cornerRadius = 2.0f;
    btn3.layer.MasksToBounds = YES;
    btn3.layer.cornerRadius = 2.0f;
    
    btn1.frame = Rect(30, 30, kScreenWidth-60, 45);
    btn2.frame = Rect(30, 90, kScreenWidth-60, 45);
    btn3.frame = Rect(30, 150, kScreenWidth-60, 45);
    
    [btn1 addTarget:self action:@selector(onAddPhoto:) forControlEvents:UIControlEventTouchUpInside];
    [btn2 addTarget:self action:@selector(onAddCamre:) forControlEvents:UIControlEventTouchUpInside];
    [btn3 addTarget:self action:@selector(viewHidden) forControlEvents:UIControlEventTouchUpInside];
    
    [_hiddenView addSubview:btn1];
    [_hiddenView addSubview:btn2];
    [_hiddenView addSubview:btn3];
    _hiddenView.hidden = YES;
}

-(void)viewHidden
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:2.3];
    _hiddenView.hidden = YES;
    [UIView commitAnimations];
}

- (void)onAddPhoto:(UIButton *)sender
{
    _imagePicker = [[UIImagePickerController alloc] init];//
    _imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    _imagePicker.delegate = self;
    _imagePicker.allowsEditing = NO;
    [self presentViewController:_imagePicker animated:YES completion:^{}];
    
}
-(void)onAddCamre:(UIButton *)sender
{
    _camrePicker = [[UIImagePickerController alloc] init];//
    _camrePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _camrePicker.delegate = self;
    _camrePicker.allowsEditing = NO;
    [self presentViewController:_camrePicker animated:YES completion:^{}];
}

-(void)updatePwd
{
    UpdPwdViewController *upd = [[UpdPwdViewController alloc] init];
    [self presentViewController:upd animated:YES completion:nil];
}

-(void)initData
{
    if (_userServie==nil)
    {
        _userServie = [[UserInfoService alloc] init];
    }
    __weak UserInfoVIewController *weakSelf = self;
    _userServie.httpBlock = ^(UserAllInfoModel *user,int nStatus)
    {
        switch (nStatus) {
            case 1:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.userAll = user;
                    [weakSelf.tableView reloadData];
                });
            }
            break;
            default:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [weakSelf.view makeToast:XCLocalized(@"userTimeout")];
                });
            }
            break;
        }
    };
    [_userServie requestUserInfo];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger nRow = 0;
    switch (section) {
        case 0:
            nRow = 2;
            break;
        case 1:
            nRow = 3;
            break;
    }
    return nRow;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        static NSString *strUserInfo = @"XCUserAllInfo";
        static NSString *strImageInfo = @"xcUserImageCell";
        if(indexPath.section ==0 && indexPath.row==0)
        {
            UserImageCell *imgCell = [tableView dequeueReusableCellWithIdentifier:strImageInfo];
            if (imgCell==nil)
            {
                imgCell = [[UserImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strImageInfo];
            }
            [imgCell.imgView setImage:[UIImage imageNamed:@"user_pic"]];
            [imgCell.lblDevInfo setText:XCLocalized(@"Useravatar")];
            __weak UserImageCell *_imgCell = imgCell;
            imgCell.imageLoad = ^(UIImage *image)
            {
                _imgCell.imgView.image = image;
            };
            [imgCell setImageInfo:_userAll.strFile];
            imgCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return imgCell;
        }
        UserInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:strUserInfo];
        if (cell==nil)
        {
            cell = [[UserInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strUserInfo];
        }
        switch (indexPath.section)
        {
            case 0:
            {
                switch (indexPath.row)
                {
                    case 1:
                    {
                        cell.lblDevInfo.text = XCLocalized(@"Nickname");
                        cell.lblContext.text = [_userAll.strOnlyName isEqualToString:@""] ? USER_INFO_NULL : _userAll.strOnlyName;
                        [cell addView:0 height:43];
                    }
                    break;
                }
            }
            break;
            case 1:
            {
                switch (indexPath.row)
                {
                    case 0:
                    {
                        [cell addView:0 height:0];
                        cell.lblDevInfo.text = XCLocalized(@"RealName");
                        cell.lblContext.text = [_userAll.strName isEqualToString:@""] ? USER_INFO_NULL : _userAll.strName;
                        [cell addView:18 height:43];
                    }
                    break;
                    case 1:
                    {
                        cell.lblDevInfo.text = XCLocalized(@"email");
                        cell.lblContext.text = [_userAll.strEmail isEqualToString:@""] ? USER_INFO_NULL : _userAll.strEmail;
                        [cell addView:18 height:43];
                    }
                    break;
                    case 2:
                    {
                        cell.lblDevInfo.text = XCLocalized(@"mobile");
                        cell.lblContext.text = [_userAll.strMobile isEqualToString:@""] ? USER_INFO_NULL : _userAll.strMobile;
                        [cell addView:0 height:43.25];
                        return cell;
                    }
                    break;
                }
            }
            break;
        }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        
        case 0:
        {
            switch (indexPath.row)
            {
                case 1:
                {
                    UpdNikNameViewController *upd= [[UpdNikNameViewController alloc] init];
                    [self presentViewController:upd animated:YES completion:nil];
                }
                break;
                case 0:
                {
                    _hiddenView.hidden = NO;
                }
                break;
            }
        }
        break;
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                {
                    UpdRealViewController *upd = [[UpdRealViewController alloc] init];
                    [self presentViewController:upd animated:YES completion:nil];
                }
                    break;
                case 1:
                {
                    UpdEmailViewController *updEmail = [[UpdEmailViewController alloc] init];
                    [self presentViewController:updEmail animated:YES completion:nil];
                }
                    break;
                case 2:
                {
                    
                }
                break;
                case 3:
                {
                
                }
                break;
                default:
                break;
            }
        }
            break;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
#pragma mark 高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row==0) {
        return 67;
    }
    return 44.5;//67+44.5*4+80
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* image = nil;
    image = [info objectForKey: @"UIImagePickerControllerOriginalImage"];

    [self dismissViewControllerAnimated:YES completion:^{}];
    //圆形图片剪切
    RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:image cropMode:RSKImageCropModeCircle];
    imageCropVC.delegate = self;
    [self presentViewController:imageCropVC animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}


#pragma mark - RSKImageCropViewControllerDelegate

- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropViewController:(RSKImageCropViewController *)controller didCropImage:(UIImage *)croppedImage
{
//    [self.addPhotoButton setImage:croppedImage forState:UIControlStateNormal];
    //coppedImage
    [self dismissViewControllerAnimated:YES completion:nil];
    [self uploadImage:croppedImage];
}

-(void)uploadImage:(UIImage*)image
{
    __weak UserInfoVIewController *__weakSelf = self;
    _upload.httpBlock = ^(int nStatus)
    {
        switch (nStatus) {
            case 1:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [__weakSelf.hiddenView setHidden:YES];
                    [__weakSelf.view makeToast:XCLocalized(@"uploadDone")];
                    [__weakSelf initData];
                });
                
            }
            break;
                
            default:
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [__weakSelf.hiddenView setHidden:YES];
                    [__weakSelf.view makeToast:@"上传失败"];
                });
            }
            break;
        }
    };
    [_upload requestUpload:image];
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
