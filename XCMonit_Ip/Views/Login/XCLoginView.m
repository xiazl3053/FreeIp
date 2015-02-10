//
//  XCLoginView.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-19.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "XCLoginView.h"

@interface XCLoginView()<XCLoginDelegate>
{
    
}
@property (nonatomic,strong) UIButton *btnLogin;
@property (nonatomic,strong) UIButton *btnRegin;
@property (nonatomic,strong) UIImageView *imgBg;
@property (nonatomic,strong) UITextField *txtUser;
@property (nonatomic,strong) UITextField *txtPwd;
@end

@implementation XCLoginView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}
-(void)layoutSubviews
{
    [super layoutSubviews];
    _imgBg = [[UIImageView alloc] initWithFrame:CGRectMake(100, HEIGHT_MENU_VIEW(20, 0)+160, 120, 120)];
    _txtUser = [[UITextField alloc] initWithFrame:CGRectMake(20, 308, 280, 40)];
    _txtPwd = [[UITextField alloc] initWithFrame:CGRectMake(20, 358, 280, 40)];
    
    [_imgBg setImage:[UIImage imageNamed:@"loginBG"]];
    
    [_txtUser setBorderStyle:UITextBorderStyleRoundedRect];
    [_txtPwd setBorderStyle:UITextBorderStyleRoundedRect];
    _txtUser.autocorrectionType = UITextAutocorrectionTypeNo;
    _txtUser.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _txtUser.returnKeyType = UIReturnKeyDone;
    _txtUser.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    
    
    [_txtUser setReturnKeyType:UIReturnKeyNext];
    [_txtUser setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [_txtPwd setReturnKeyType:UIReturnKeyDone];
    [_txtPwd setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [_txtUser setPlaceholder:@"用户名"];
    [_txtPwd setPlaceholder:@"密  码"];
    
    _txtUser.delegate = self;
    _txtPwd.delegate = self;
    
    _txtUser.tag = 1;
    _txtPwd.tag = 2;
    
    [_txtPwd setSecureTextEntry:YES];
    _btnLogin = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnRegin = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnLogin setFrame:CGRectMake(40, 420, 100, 39)];
    [_btnLogin setBackgroundImage:[UIImage imageNamed:@"btnBG"] forState:UIControlStateNormal];
    [_btnRegin setFrame:CGRectMake(180, 420, 100, 39)];
    [_btnRegin setBackgroundImage:[UIImage imageNamed:@"btnBG"] forState:UIControlStateNormal];
    
    [_btnLogin setTitle:@"登录" forState:UIControlStateNormal];
    
    
    [_btnRegin setTitle:@"注册" forState:UIControlStateNormal];
    [_btnLogin addTarget:self action:@selector(loginServer) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:_imgBg];
    [self addSubview:_txtUser];
    [self addSubview:_txtPwd];
    [self addSubview:_btnLogin];
    [self addSubview:_btnRegin];
    
}

-(void)loginServer
{
    NSString *nsUser = [_txtUser text];
    NSString *nsPwd = [_txtPwd text];
    if ([nsUser isEqualToString:@""] || [nsUser length]==0) {
        DLog(@"用户名不能为空");
    }else if([nsPwd isEqualToString:@""] || [nsPwd length]==0)
    {
        DLog(@"密码不能为空");
    }else
    {
        [_txtUser resignFirstResponder];
        [_txtPwd resignFirstResponder];
        if (_delegate && [_delegate respondsToSelector:@selector(loginViewButtonLogin:pwd:)])
        {
            [_delegate loginViewButtonLogin:nsUser pwd:nsPwd];
        }
    }
}
-(void)dealloc
{
    _txtUser = nil;
    _txtPwd = nil;
    _imgBg = nil;
    _btnRegin = nil;
    _btnLogin = nil;
}

#pragma mark 键盘事件


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.placeholder = nil;
    if (_delegate && [_delegate respondsToSelector:@selector(loginViewKeyboardOpen)])
    {
        [_delegate loginViewKeyboardOpen];
    }
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (_delegate && [_delegate respondsToSelector:@selector(loginViewKeyboardClose)])
    {
        [_delegate loginViewKeyboardClose];
    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (_delegate && [_delegate respondsToSelector:@selector(loginViewKeyboardClose)])
    {
        [_delegate loginViewKeyboardClose];
    }
    if (textField == _txtUser)
    {
        [_txtUser resignFirstResponder];
        [_txtPwd becomeFirstResponder];
    }
    else if (textField == _txtPwd)
    {
        [self loginServer];
    }
    return YES;
}

-(void)setLoginInfo:(NSString*)strUser pwd:(NSString*)strPwd
{
    __weak XCLoginView *wearSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        wearSelf.txtUser.text = strUser;
        wearSelf.txtPwd.text = strPwd;
    //    [wearSelf.txtUser setPlaceholder:@""];
    //    [wearSelf.txtPwd setPlaceholder:@""];
    });
    
}
-(BOOL)pwdIsFirstResponder
{
    return [_txtPwd isFirstResponder];
}
-(void)closeKeyBoard
{
    [_txtUser resignFirstResponder];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
