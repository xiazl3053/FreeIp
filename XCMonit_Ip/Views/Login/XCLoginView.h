//
//  XCLoginView.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-19.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XCLoginDelegate <NSObject>

@optional

-(void)loginViewKeyboardOpen;
-(void)loginViewKeyboardClose;
-(void)loginViewButtonLogin:(NSString*)nsUser pwd:(NSString*)nsPwd;
@end


@interface XCLoginView : UIView <UITextFieldDelegate>

@property (nonatomic,assign) id<XCLoginDelegate> delegate;


-(void)setLoginInfo:(NSString*)strUser pwd:(NSString*)strPwd;

-(BOOL)pwdIsFirstResponder;
-(void)loginServer;
-(void)closeKeyBoard;
@end
