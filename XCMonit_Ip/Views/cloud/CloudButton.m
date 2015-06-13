//
//  XCButton.m
//  FreeIp
//
//  Created by 夏钟林 on 15/3/27.
//  Copyright (c) 2015年 xiazl. All rights reserved.
//

#import "CloudButton.h"

@implementation CloudButton
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(id)initWithFrame:(CGRect)frame normal:(NSString *)strNor high:(NSString *)strHight
{
    self = [super initWithFrame:frame];
    [self setNormal:strNor];
    [self setHigh:strHight];
    return  self;
}


-(id)initWithFrame:(CGRect)frame normal:(NSString *)strNor
{
    self = [super initWithFrame:frame];
    [self setNormal:strNor];
    return self;
}

-(id)initWithFrame:(CGRect)frame normal:(NSString *)strNor high:(NSString *)strHigh select:(NSString *)strSelect
{
    self = [super initWithFrame:frame];
    
    [self setNormal:strNor];
    [self setHigh:strHigh];
    [self setSelectImg:strSelect];
    
    return self;
}

-(void)setNormal:(NSString *)strNor
{
    [self setImage:[UIImage imageNamed:strNor] forState:UIControlStateNormal];
}

-(void)setHigh:(NSString *)strHigh
{
    [self setImage:[UIImage imageNamed:strHigh] forState:UIControlStateHighlighted];
}

-(void)setSelectImg:(NSString *)strSelect
{
    [self setImage:[UIImage imageNamed:strSelect] forState:UIControlStateSelected];
}

@end
