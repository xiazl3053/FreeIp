//
//  ImageCellTableViewCell.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/11.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCell : UITableViewCell


@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,strong) NSString *strFile;


- (void)tapImage:(UITapGestureRecognizer *)tap;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
-(void)setArrayInfo:(NSArray*)array;
-(void)freshCell;

@end
