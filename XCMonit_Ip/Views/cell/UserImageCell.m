//
//  UserImageCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "UserImageCell.h"
#import "UIImageView+WebCache.h"


@implementation UserImageCell

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
    _lblDevInfo = [[UILabel alloc] initWithFrame:CGRectMake(5, self.contentView.frame.size.height/2-8, 150, 16)];
    _imgView = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width-50, self.contentView.frame.size.height/2-15, 40, 30)];
    [_lblDevInfo setFont:[UIFont systemFontOfSize:16.0f]];
    
    [_lblDevInfo setTextColor:[UIColor blackColor]];

    [self.contentView addSubview:_lblDevInfo];
    [self.contentView addSubview:_imgView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, self.contentView.frame.size.height-1, kScreenWidth, 1)];
    [lineView setBackgroundColor:[UIColor grayColor]];
    [self.contentView addSubview:lineView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setImageInfo:(NSString*)strImage
{
    [_imgView setImageWithURL:[NSURL URLWithString:strImage] placeholderImage:[UIImage imageNamed:@"user_pic"]];
//    [_imgView setImageWithURL:[NSURL URLWithString:strImage]];
//    dispatch_async(dispatch_get_global_queue(0, 0),
//   ^{
//       UIImage *image = [[UIImage alloc] initWithContentsOfFile:[weakSelf.array objectAtIndex:i]];
//       dispatch_async(dispatch_get_main_queue(),^
//                      {
//                          [imageView setImage:image];
//                      });
//   });
}
@end
