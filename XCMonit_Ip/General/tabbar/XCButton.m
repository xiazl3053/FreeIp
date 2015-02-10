//
//  XCButton.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "XCButton.h"

@interface XCButton()

@property (nonatomic,strong) UIImage *imgNormal;
@property (nonatomic,strong) UIImage *imgSelect;

@end

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

-(id)initWithTabInfo:(XCTabInfo*)tabInfo frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:9.0f];
        
        [self setTitle:tabInfo.strTitle forState:UIControlStateNormal];
        [self setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self setTitleColor:RGB(21,100,230) forState:UIControlStateSelected];

        _imgNormal = [UIImage imageNamed:tabInfo.strNorImg];
        _imgSelect = [UIImage imageNamed:tabInfo.strHighImg];
        
        self.contentMode = UIViewContentModeScaleAspectFit;
        [self setImage:_imgNormal forState:UIControlStateNormal];
        [self setImage:_imgSelect forState:UIControlStateSelected];
    }
    return self;
}

-(CGRect)imageRectForContentRect:(CGRect)bounds
{
    return CGRectMake(6.5,3, 27, 27);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(0.0, 30, 40, 10);
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
