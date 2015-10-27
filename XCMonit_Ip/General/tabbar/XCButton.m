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
        
        self.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
        
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
        self.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0f];
        
        [self setTitle:tabInfo.strTitle forState:UIControlStateNormal];
        [self setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [self setTitleColor:RGB(15,173,225) forState:UIControlStateSelected];

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
    
    return CGRectMake(9, 3, 30, 30);//49
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(0.0, 33, 48, 15);
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
