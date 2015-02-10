//
//  VIdeoView.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/29.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "VIdeoView.h"

@interface VideoView()
{
    
}
@property (nonatomic,strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic,strong) UITapGestureRecognizer *doubleGesture;
@end

@implementation VideoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setBackgroundColor:RGB(0, 0,0)];
        
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOnView)];
        _doubleGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleClickView)];
        _tapGesture.numberOfTapsRequired =1;
        _doubleGesture.numberOfTapsRequired = 2;
        [self setUserInteractionEnabled:YES];
        [self addGestureRecognizer:_tapGesture];
        [self addGestureRecognizer:_doubleGesture];
    }
    return self;
}
-(void)clickOnView
{
    if ([_delegate respondsToSelector:@selector(clickView:)])
    {
        [_delegate clickView:self];
    }
}
-(void)doubleClickView
{
    if ([_delegate respondsToSelector:@selector(doubleClickVideo:)])
    {
        [_delegate doubleClickVideo:self];
    }
}


@end
