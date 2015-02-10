//
//  UserInfoCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/11.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "UserInfoCell.h"

@implementation UserInfoCell

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
    _lblDevInfo = [[UILabel alloc] initWithFrame:CGRectMake(20, self.contentView.frame.size.height/2-10, 100, 20)];
    _lblContext = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth-185, self.contentView.frame.size.height/2-10, 150, 20)];
    [_lblDevInfo setFont:[UIFont fontWithName:@"Helvetica" size:16.0f]];
    [_lblContext setFont:[UIFont fontWithName:@"Helvetica" size:16.0f]];
    
    [_lblDevInfo setTextColor:RGB(180, 180, 180)];
    [_lblContext setTextColor:RGB(98, 98, 98)];
    [_lblContext setTextAlignment:NSTextAlignmentRight];
    [self.contentView addSubview:_lblDevInfo];
    [self.contentView addSubview:_lblContext];
    
}

-(void)addView:(CGFloat)fWidth height:(CGFloat)fHeight
{
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(fWidth, fHeight+0.25, kScreenWidth, 0.5)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(fWidth, fHeight+0.75, kScreenWidth, 0.5)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    
    [self.contentView addSubview:sLine1];
    [self.contentView addSubview:sLine2];
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
