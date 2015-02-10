//
//  DevNameCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/20.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "DevNameCell.h"
#import "UtilsMacro.h"
@interface DevNameCell()
{
    UIImageView *_imgView;
    UILabel *_lblName;
}
@end


@implementation DevNameCell
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
    _imgView = [[UIImageView alloc] initWithFrame:Rect(15, 3, 45, 45)];
    [self.contentView addSubview:_imgView];
    _lblName = [[UILabel alloc] initWithFrame:Rect(100, 20, 210, 12)];
    [_lblName setTextAlignment:NSTextAlignmentRight];
    [_lblName setFont:[UIFont systemFontOfSize:14.0f]];
    [self.contentView addSubview:_lblName];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
}
-(void)setDevInfo:(NSString*)strPath name:(NSString*)strName
{
    [_imgView setImage:[UIImage imageNamed:strPath]];
    [_lblName setText:strName];
}
-(void)dealloc
{
    _imgView = nil;
    _lblName = nil;
}


@end
