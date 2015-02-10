//
//  PictureView.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "PictureView.h"

@interface PictureView()
@property (nonatomic,strong) UIView *viewInfo;
@end


@implementation PictureView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imgView = [[UIImageView alloc] initWithFrame:Rect(0,0, frame.size.width, 90)];
        _viewInfo = [[UIView alloc] initWithFrame:Rect(0, 88, frame.size.width, 54)];
        
        _imgSelect = [[UIImageView alloc] initWithFrame:self.bounds];
        _imgSelect.image = [UIImage imageNamed:@"default_select"];
        _imgSelect.alpha = 0.6;
        _imgSelect.hidden = YES;
        
        _lblDev = [[UILabel alloc] initWithFrame:Rect(0, 12 , frame.size.width , 16)];
        _lblTime = [[UILabel alloc] initWithFrame:Rect(0, 35, frame.size.width , 12)];
        [_lblDev setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
        [_lblTime setFont:[UIFont fontWithName:@"Helvetica" size:12.0f]];
        _lblDev.textColor = [UIColor blackColor];
        _lblTime.textColor = [UIColor grayColor];
        
        [_lblDev setTextAlignment:NSTextAlignmentCenter];
        [_lblTime setTextAlignment:NSTextAlignmentCenter];
        
        [_viewInfo addSubview:_lblDev];
        [_viewInfo addSubview:_lblTime];
        
        _viewInfo.layer.borderColor = (RGB(217, 217, 217)).CGColor;
        _viewInfo.layer.borderWidth = 1.0f;
        
        [self addSubview:_viewInfo];
        [self addSubview:_imgView];
        [self addSubview:_imgSelect];
    }
    return self;
}

-(void)dealloc
{
    _viewInfo = nil;
    _imgSelect = nil;
    _imgView = nil;
    _lblDev = nil;
    _lblTime = nil;
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
