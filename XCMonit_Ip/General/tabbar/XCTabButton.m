//
//  MyNBTabButton.m
//  NB2
//
//  Created by kohn on 13-11-16.
//  Copyright (c) 2013年 Kohn. All rights reserved.
//

#import "XCTabButton.h"
@interface XCTabButton()


@property (nonatomic,strong) UIImage *highImg;
@property (nonatomic,strong) UIImage *norImg;
@end

@implementation XCTabButton

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame title:(NSString*)strTitle norCon:(NSString*)strNorCon highCon:(NSString*)strHighCon
{
    self = [super initWithFrame:frame];
    _highImg = [UIImage imageNamed:strHighCon];
    _norImg = [UIImage imageNamed:strNorCon];
    return self;
}


-(void)setHighlighted:(BOOL)highlighted
{
    [self.imageView setImage:_highImg];
}
#define kImageScale   0.6
- (CGRect)imageRectForContentRect:(CGRect)contentRect

{
    
    CGFloat imgW = contentRect.size.width;
    
    CGFloat imgH = contentRect.size.height * kImageScale;
    
    return CGRectMake(0, 0, imgW, imgH);
    
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect

{
    CGFloat titleW = contentRect.size.width;
    CGFloat titleY = contentRect.size.height * kImageScale;
    CGFloat titleH = contentRect.size.height - titleY;
    
    return CGRectMake(0, titleY, titleW, titleH);
}

@end
