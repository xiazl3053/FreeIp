//
//  XCButton.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XCTabInfo : NSObject

@property (nonatomic,strong) NSString *strTitle;
@property (nonatomic,strong) NSString *strNorImg;
@property (nonatomic,strong) NSString *strHighImg;
@property (nonatomic,strong) UIViewController *viewController;

-(id)initWithTabInfo:(NSString *)title normal:(NSString *)norImg high:(NSString*)strHighImg;

@end

@interface XCButton : UIButton


-(id)initWithTabInfo:(XCTabInfo*)tabInfo frame:(CGRect)frame;


@end

