//
//  XCMoreButton.m
//  XCMonit_Ip
//
//  Created by xiongchi on 15/10/10.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "XCMoreButton.h"
#define XCMOREBTNWIDTH    60
@implementation XCMoreButton

- (id)initWithFrame:(CGRect)frame info:(XCMoreInfo *)more
{
    self = [super initWithFrame:frame];
    
    
    [self setImage:[UIImage imageNamed:more.strNormal] forState:UIControlStateNormal];
    [self setImage:[UIImage imageNamed:more.strHigh] forState:UIControlStateHighlighted];
    
    [self setTitle:more.strTitle forState:UIControlStateNormal];
    
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.titleLabel.font = XCFontInfo(12);
    
    [self setTitleColor:UIColorFromRGBHex(0x3f4749) forState:UIControlStateNormal];
    
    return self;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return Rect(0,self.frame.size.height-15,self.frame.size.width,13);
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    return Rect(self.frame.size.width/2-30,0,XCMOREBTNWIDTH,XCMOREBTNWIDTH);
}

@end


@implementation XCMoreInfo

- (id)initWithInfo:(NSString *)strTitle normal:(NSString *)strNormal high:(NSString *)strHigh
{
    self = [super init];
    
    _strNormal = strNormal;
    _strTitle = strTitle;
    _strHigh = strHigh;
    
    return self;
}

@end
