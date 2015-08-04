//
//  EICheckBox.m
//  EInsure
//
//  Created by ivan on 13-7-9.
//  Copyright (c) 2013年 ivan. All rights reserved.
//

#import "QCheckBox.h"

#define Q_CHECK_ICON_WH                    (30)
#define Q_ICON_TITLE_MARGIN                (1)

@implementation QCheckBox

@synthesize delegate = _delegate;
@synthesize checked = _checked;
@synthesize userInfo = _userInfo;

- (id)initWithDelegate:(id)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        self.exclusiveTouch = YES;
        [self setImage:[UIImage imageNamed:@"check"] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"check_h"] forState:UIControlStateSelected];
        [self addTarget:self action:@selector(checkboxBtnChecked) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setChecked:(BOOL)checked {
    if (_checked == checked) {
        return;
    }
    
    _checked = checked;
    self.selected = checked;
    
    if (_delegate && [_delegate respondsToSelector:@selector(didSelectedCheckBox:checked:)]) {
        [_delegate didSelectedCheckBox:self checked:self.selected];
    }
}

- (void)checkboxBtnChecked {
    self.selected = !self.selected;
    _checked = self.selected;
    
    if (_delegate && [_delegate respondsToSelector:@selector(didSelectedCheckBox:checked:)]) {
        [_delegate didSelectedCheckBox:self checked:self.selected];
    }
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(0,0, Q_CHECK_ICON_WH, Q_CHECK_ICON_WH);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(Q_CHECK_ICON_WH+1,0,
                      CGRectGetWidth(contentRect) - Q_CHECK_ICON_WH,
                      CGRectGetHeight(contentRect));
}

- (void)dealloc {
    [_userInfo release];
    _delegate = nil;
    [super dealloc];
}

@end
