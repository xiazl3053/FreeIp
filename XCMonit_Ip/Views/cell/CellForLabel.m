//
//  CellForLabel.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/1.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "CellForLabel.h"

@implementation CellForLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setFont:[UIFont systemFontOfSize:15.0f]];
        [self setTextColor:[UIColor blackColor]];
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame font:(CGFloat)size
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setFont:[UIFont systemFontOfSize:size]];
        [self setTextColor:[UIColor blackColor]];
    }
    return self;
}



@end
