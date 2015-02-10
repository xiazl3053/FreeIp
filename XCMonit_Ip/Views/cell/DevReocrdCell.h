//
//  DevReocrdCellTableViewCell.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/30.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RecordModel;
@interface DevReocrdCell : UITableViewCell

@property (nonatomic,strong) UIImageView *imgView;

-(void)setRecordInfo:(RecordModel*)record;

@end
