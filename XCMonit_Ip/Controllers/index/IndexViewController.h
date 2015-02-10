//
//  IndexViewController.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-20.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UtilsMacro.h"

@interface IndexViewController : UIViewController


DEFINE_SINGLETON_FOR_HEADER(IndexViewController);
-(void)closeIndexView;
-(void)setInit;
-(void)setIndexViewController:(int)nIndex;
@end
