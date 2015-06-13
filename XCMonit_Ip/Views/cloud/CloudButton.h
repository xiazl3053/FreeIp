//
//  XCButton.h
//  FreeIp
//
//  Created by 夏钟林 on 15/3/27.
//  Copyright (c) 2015年 xiazl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CloudButton : UIButton




-(id)initWithFrame:(CGRect)frame normal:(NSString *)strNor high:(NSString *)strHight;

-(id)initWithFrame:(CGRect)frame normal:(NSString *)strNor;

-(id)initWithFrame:(CGRect)frame normal:(NSString *)strNor high:(NSString *)strHigh select:(NSString *)strSelect;


@end
