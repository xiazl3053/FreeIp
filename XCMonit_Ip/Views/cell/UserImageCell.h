//
//  UserImageCell.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserImageCell : UITableViewCell

@property (nonatomic,strong) UILabel *lblDevInfo;
@property (nonatomic,strong) UIImageView *imgView;

-(void)setImageInfo:(NSString*)strImage;


@end
