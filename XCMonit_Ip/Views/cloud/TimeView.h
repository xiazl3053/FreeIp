//
//  TimeView.h
//  TestInfo
//
//  Created by 夏钟林 on 15/5/25.
//  Copyright (c) 2015年 xiazl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeView : UIView

@property (nonatomic,assign) CGFloat fValue;

@property (nonatomic,assign) int nWidth;

@property (nonatomic,strong) NSDate *dateInfo;

@property (nonatomic,assign) NSString *strTime;

-(id)initWithFrame:(CGRect)frame time:(NSString *)strTime;

-(void)settingTime:(NSString *)strTime;




@end
