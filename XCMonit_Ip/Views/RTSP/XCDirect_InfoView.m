//
//  XCDirect_InfoView.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/1/26.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "XCDirect_InfoView.h"
#import "UtilsMacro.h"
#import "UIView+convenience.h"
@interface XCDirect_InfoView()
{
    
}
@property (nonatomic,strong) UIView *viewEdit;
@property (nonatomic,strong) UIView *viewRecord;
@property (nonatomic,strong) UIImageView *imgRecord;
@property (nonatomic,strong) UIImageView *imgEdit;

@end

@implementation XCDirect_InfoView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    [self setBackgroundColor:RGB(62, 62, 62)];
    
    _viewEdit = [[UIView alloc] initWithFrame:  Rect(0   ,0,81,39)];
    _viewRecord = [[UIView alloc] initWithFrame:Rect(82,0,81,39)];//15+30+5+21
    
    _imgEdit = [[UIImageView alloc] initWithFrame:Rect(10,9.5, 20, 20)];//39  20  9.9
    _imgRecord = [[UIImageView alloc] initWithFrame:Rect(10,9.5, 20, 20)];
    
    //39/2 19-10
    
    [_viewEdit addSubview:_imgEdit];
    [_viewRecord addSubview:_imgRecord];
    
    _imgEdit.image =[UIImage imageNamed:@"editor"];
    _imgRecord.image = [UIImage imageNamed:@"file_new"];
    //81.5  35
    UILabel *lbl1 = [[UILabel alloc] initWithFrame:Rect(_imgEdit.frameX+_imgEdit.frameWidth+5,_viewEdit.frameHeight/2-6, 46, 12)];
    UILabel *lbl2 = [[UILabel alloc] initWithFrame:Rect(_imgRecord.frameX+_imgRecord.frameWidth+5,_viewRecord.frameHeight/2-6, 46, 12)];
    
    [_viewEdit addSubview:lbl1];
    [_viewRecord addSubview:lbl2];
    
    UILabel *lblH = [[UILabel alloc] initWithFrame:Rect(81, 9.5, 1, 18)];
    [self addSubview:lblH];
    [lblH setBackgroundColor:RGB(38, 38, 38)];
    
    [lbl1 setText:XCLocalized(@"editor")];
    [lbl2 setText:XCLocalized(@"recorddirect")];
    
    [lbl1 setTextColor:[UIColor whiteColor]];
    [lbl2 setTextColor:[UIColor whiteColor]];
    
    [lbl1 setFont:[UIFont fontWithName:@"Helvetica" size:11.0f]];
    [lbl2 setFont:[UIFont fontWithName:@"Helvetica" size:11.0f]];
    
    [self addSubview:_viewEdit];
    [self addSubview:_viewRecord];
    
    _viewEdit.tag = 10098;
    _viewRecord.tag = 10099;
    [_viewEdit addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickView:)]];
    [_viewRecord addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickView:)]];

    return self;
}
-(void)clickView:(UITapGestureRecognizer *)tapGecogn
{
    UIView *view = tapGecogn.view;
    if (view.tag == 10098)
    {
        //编辑
        if(_delegate && [_delegate respondsToSelector:@selector(update_Direct:)])
        {
            [_delegate update_Direct:_nCount];
        }
    }
    else if(view.tag == 10099)
    {
        //录像
        if (_delegate && [_delegate respondsToSelector:@selector(record_Direct:)])
        {
            [_delegate record_Direct:_nCount];//检查录像
        }
    }
    else
    {
        DLog(@"意外");
    }
}


@end
