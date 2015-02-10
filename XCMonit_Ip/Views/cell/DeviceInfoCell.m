//
//  DeviceInfoCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/18.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "DeviceInfoCell.h"

@implementation DeviceInfoCell



- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    _lblDevInfo = [[UILabel alloc] initWithFrame:CGRectMake(15, self.contentView.frame.size.height/2-8, 160, 20)];
    _lblContext = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width-160, self.contentView.frame.size.height/2-8, 155, 20)];
    [_lblDevInfo setFont:[UIFont systemFontOfSize:16.0f]];
    [_lblContext setFont:[UIFont systemFontOfSize:16.0f]];
    [_lblDevInfo setTextColor:[UIColor blackColor]];
    [_lblContext setTextAlignment:NSTextAlignmentRight];
    [_lblContext setTextColor:[UIColor blackColor]];
    [self.contentView addSubview:_lblDevInfo];
    [self.contentView addSubview:_lblContext];
    
    UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, self.contentView.frame.size.height-1, kScreenWidth, 1)];
    [lineView setBackgroundColor:[UIColor grayColor]];
    [self.contentView addSubview:lineView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setDevInfo:(NSString*)strInfo context:(NSString*)strContext
{
    [_lblDevInfo setText:strInfo];
    [_lblContext setText:strContext];
}
-(void)dealloc
{
    _lblDevInfo = nil;
    _lblContext = nil;
}
@end
