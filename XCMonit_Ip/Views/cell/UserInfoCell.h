//
//  UserInfoCell.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/10/11.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserInfoCell : UITableViewCell
@property (nonatomic,strong) UILabel *lblDevInfo;
@property (nonatomic,strong) UILabel *lblContext;

-(void)setDevInfo:(NSString*)strInfo context:(NSString*)strContext;
-(void)addView:(CGFloat)fWidth height:(CGFloat)fHeight;

@end
