//
//  RtspCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RtspCell.h"
#import "UtilsMacro.h"
@implementation RtspCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib
{
    _imgView = [[UIImageView alloc] initWithFrame:Rect(2, 7, 45, 45)];
    _lblDevName = [[UILabel alloc] initWithFrame:Rect(50, 3, 180, 20)];
    [_lblDevName setFont:[UIFont systemFontOfSize:16.0f]];
    _lblStatus = [[UILabel alloc] initWithFrame:Rect(52, 36, 120, 16)];
    [_lblStatus setFont:[UIFont systemFontOfSize:12.0f]];
    
    [_imgView setImage:[UIImage imageNamed:@"deviceOn"]];
    
    [self.contentView addSubview:_imgView];
    [self.contentView addSubview:_lblDevName];
    [self.contentView addSubview:_lblStatus];
    
    UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, kTableViewRTSPCellHeight-1, kScreenWidth, 1)];
    [lineView setBackgroundColor:[UIColor grayColor]];
    [self.contentView addSubview:lineView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
