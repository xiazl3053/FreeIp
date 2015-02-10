//
//  RtspCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//
//


#import "RtspCell.h"
#import "UtilsMacro.h"

#define kRtspCellBtnWidth 44
#define kRtspCellPlayBtnWidth 45

@implementation RtspCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //浏览按钮
        _imgRecord = [[UIImageView alloc] initWithFrame:Rect(kScreenWidth-50, kTableViewRTSPCellHeight/2-kRtspCellBtnWidth/2, kRtspCellBtnWidth, kRtspCellBtnWidth)];
        //设备样式图标
        _imgView = [[UIImageView alloc] initWithFrame:Rect(10, kTableViewRTSPCellHeight/2-kRtspCellPlayBtnWidth/2, kRtspCellPlayBtnWidth, kRtspCellPlayBtnWidth)];
        
        _lblDevName = [[UILabel alloc] initWithFrame:Rect(66.5, 3, 180, 20)];
        
        [_lblDevName setFont:[UIFont fontWithName:@"Helvetica" size:16.0f]];
        
        _lblStatus = [[UILabel alloc] initWithFrame:Rect(66.5, 40, 120, 16)];
        
        [_lblStatus setFont:[UIFont fontWithName:@"Helvetica" size:12.0f]];
        
        [_lblStatus setTextColor:RGB(178, 182, 186)];
        
        [_lblDevName setTextColor:RGB(115, 115, 115)];
        
        [_imgRecord setImage:[UIImage imageNamed:@"sit_button"]];
        
        _imgRecord.userInteractionEnabled = YES;
        
        [self.contentView addSubview:_imgView];
        [self.contentView addSubview:_lblDevName];
        [self.contentView addSubview:_lblStatus];
        [self.contentView addSubview:_imgRecord];
        
        [_imgRecord addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecord:)]];
        
        UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, kTableViewRTSPCellHeight-1.5, kScreenWidth, 0.5)];
        sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                                 green:198/255.0
                                                  blue:198/255.0
                                                 alpha:1.0];
        UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, kTableViewRTSPCellHeight-1, kScreenWidth, 0.5)] ;
        
        sLine2.backgroundColor = [UIColor whiteColor];
        
        [self.contentView addSubview:sLine1];
        [self.contentView addSubview:sLine2];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)tapRecord:(UITapGestureRecognizer*)tapGesture
{
    
    if (_delegate && [_delegate respondsToSelector:@selector(recordVideoByIndex:path:)]) {
        [_delegate recordVideoByIndex:_nIndex path:_nsIndexPath];
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
