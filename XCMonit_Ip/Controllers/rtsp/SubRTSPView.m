//
//  SubCateViewController.m
//  top100
//
//  Created by Dai Cloud on 12-7-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SubRTSPView.h"
#define COLUMN 4

@interface SubRTSPView ()

@end

@implementation SubRTSPView


- (void)dealloc
{

}

-(id)init
{
    self = [super init];
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.backgroundColor = RGB(52, 78, 147);
    // init cates show
    NSInteger total = _nCount;
#define ROWHEIHT 70
    int rows = (int)(total / COLUMN) + ((total % COLUMN) > 0 ? 1 : 0);
    CGRect viewFrame = self.frame;
    viewFrame.size.height = rows*70+20;
    self.frame = viewFrame;
    UIScrollView *scrolView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 280)];
    [self addSubview:scrolView];
    for (int i=0; i<total; i++)
    {
        int row = i / COLUMN;
        int column = i % COLUMN;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake((kScreenWidth/4)*column, ROWHEIHT*row, (kScreenWidth/4), ROWHEIHT)] ;
        view.backgroundColor = [UIColor clearColor];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(15, 15, 50, 50);
        btn.layer.masksToBounds = YES;
        btn.layer.cornerRadius = 25.0f;
        
        btn.tag = i+1;
        [btn addTarget:self action:@selector(testInfo:) forControlEvents:UIControlEventTouchUpInside];
        NSString *strImg = [NSString stringWithFormat:@"%d",i+1];
        [btn setTitle:strImg forState:UIControlStateNormal];
        [btn setBackgroundColor:[UIColor whiteColor]];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [view addSubview:btn];
        [scrolView addSubview:view];
    }
    scrolView.contentSize = CGSizeMake(kScreenWidth,80*rows);
    scrolView.pagingEnabled=YES;
    [scrolView setScrollEnabled:YES];
}
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

-(void)testInfo:(UIButton*)sender
{
    NSInteger nChannel = [sender.titleLabel.text integerValue];
    if (_delegate && [_delegate respondsToSelector:@selector(playRtspConnect:)]) {
        [_delegate playRtspConnect:nChannel];
    }
}

@end










