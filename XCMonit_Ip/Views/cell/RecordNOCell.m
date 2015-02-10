//
//  RecordNOCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/12.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RecordNOCell.h"
#import "RecordView.h"
#import "UtilsMacro.h"
#import "RecordModel.h"
@interface RecordNOCell()
{
    
}

@end

@implementation RecordNOCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setArrayRecord:(NSArray *)arrayRecord
{
    if(_arrayRecord)
    {
        _arrayRecord = nil;
    }
    if (arrayRecord && arrayRecord >0) {
        _arrayRecord = [[NSArray alloc] initWithArray:arrayRecord];
    }else
    {
        _arrayRecord = [[NSArray alloc] init];
    }
    [self freshCell];
}

-(void)freshCell
{

    for (UIView *view in self.contentView.subviews)
    {
        [view removeFromSuperview];
    }
    CGFloat width = kScreenWidth/3-2;
    CGFloat height = 144;
    NSInteger nLength = _arrayRecord.count;

    for (int i = 0; i<nLength; i++)
    {
        // 计算位置
        int row = i/3;
        int column = i%3;
        CGFloat x = 1 + column * (width+2);
        CGFloat y = 4 + row * height;
        RecordView *rdView = [[RecordView alloc] initWithFrame:Rect(x, y, width, height)];
        [self.contentView addSubview:rdView];
        RecordModel *record = (RecordModel *)([_arrayRecord objectAtIndex:i]);
        
        [rdView.lblDev setText:record.strDevName];//设备名
        
        NSString *strTime = ([[record.strStartTime stringByDeletingPathExtension] componentsSeparatedByString:@" "])[1];

        if ([strTime rangeOfString:@"-"].location != NSNotFound)
        {
            NSString *newStrTime = [strTime stringByReplacingOccurrencesOfString:@"-" withString:@":"];
            [rdView.lblTime setText:newStrTime];//时间
        }
        else
        {
            [rdView.lblTime setText:strTime];
        }
        //
        
        rdView.imgView.userInteractionEnabled=YES;//图片属性设置
        [rdView.imgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecord:)]];
        rdView.imgView.tag = record.nId + 1000;
        
        __weak RecordView *__rdView = rdView;
        NSString *strPath = [NSString stringWithFormat:@"%@/record/%@",kLibraryPath,record.imgFile];
        __block NSString *__strPath = strPath;
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:__strPath];
            dispatch_async(dispatch_get_main_queue(),^
            {
                 [__rdView.imgView setImage:image];
            });
       });
    }
}

-(void)tapRecord:(UITapGestureRecognizer*)tapGesture
{
    NSInteger nTag = tapGesture.view.tag-1000;
    if (_delegate && [_delegate respondsToSelector:@selector(recordNOCell:index:)])
    {
        [_delegate recordNOCell:tapGesture.view index:nTag];
    }
}


@end
