//
//  XCButton.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "XCButton.h"

@implementation XCButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:9.0f];

        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor greenColor] forState:UIControlStateSelected];
    }
    return self;
}

//-(void)layoutSubviews
//{
//    [self layoutSubviews];
//    self.titleLabel.textAlignment = NSTextAlignmentCenter;
//}

- (CGRect)imageRectForContentRect:(CGRect)bounds
{
    return CGRectMake(0.0, 0.0, 44, 44);
}
- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(0.0, 44, 44, 10);
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
