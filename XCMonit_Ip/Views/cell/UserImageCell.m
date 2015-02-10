//
//  UserImageCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "UserImageCell.h"

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
    UILabel *sLine3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 0.5)];
    sLine3.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.5, kScreenWidth, 0.5)] ;
    sLine4.backgroundColor = [UIColor whiteColor];
    
    [self.contentView addSubview:sLine3];
    [self.contentView addSubview:sLine4];
    
    
    _lblDevInfo = [[UILabel alloc] initWithFrame:CGRectMake(18, 25, 150, 16)];
    _imgView = [[UIImageView alloc] initWithFrame:CGRectMake(kScreenWidth-75, 11 , 45, 45)];
    [_lblDevInfo setFont:[UIFont fontWithName:@"Helvetica" size:16.0f]];
    
    [_lblDevInfo setTextColor:RGB(180, 180, 180)];
    _imgView.layer.MasksToBounds = YES;
    _imgView.layer.cornerRadius = 22.5f;
    [self.contentView addSubview:_lblDevInfo];
    [self.contentView addSubview:_imgView];
    
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(18, 65.5, kScreenWidth, 0.5)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(18, 66, kScreenWidth, 0.5)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    
    [self.contentView addSubview:sLine1];
    [self.contentView addSubview:sLine2];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setImageInfo:(NSString*)strImage
{
    __block NSString *__strPath = strImage;
    __block UserImageCell *imageCell = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        DLog(@"Starting: %@", __strPath);
        UIImage *avatarImage = nil;
        NSURL *url = [NSURL URLWithString:__strPath];
        NSData *responseData = [NSData dataWithContentsOfURL:url];
        avatarImage = [UIImage imageWithData:responseData];
        DLog(@"Finishing: %@", __strPath);
        
        if (avatarImage)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (imageCell.imageLoad) {
                    imageCell.imageLoad(avatarImage);
                }
            });
        }
        else {
            DLog(@"-- impossible download: %@", __strPath);
        }
    });
}
@end
