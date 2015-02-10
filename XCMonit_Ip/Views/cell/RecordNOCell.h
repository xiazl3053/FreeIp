//
//  RecordNOCell.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/12.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RecordNOCell;

@protocol RecordNOCellDelegate <NSObject>

-(void)recordNOCell:(UIView*)view index:(NSInteger)nId;

@end


@interface RecordNOCell : UITableViewCell

@property (nonatomic, assign)   id <RecordNOCellDelegate>  delegate;
@property (nonatomic,strong) NSArray *arrayRecord;

@end
