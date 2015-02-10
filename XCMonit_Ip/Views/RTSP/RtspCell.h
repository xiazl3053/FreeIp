//
//  RtspCell.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/14.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RtspCellDelegate <NSObject>
-(void)recordVideoByIndex:(NSInteger)nIndex path:(NSIndexPath*)nsIndexPath;
//-(void)recordVideoByIndex:(NSInteger)nIndex row:(NSInteger)nRow;

@end


@interface RtspCell : UITableViewCell

@property (nonatomic,assign) id<RtspCellDelegate> delegate;

@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) UILabel *lblDevName;
@property (nonatomic,strong) UILabel *lblStatus;
@property (nonatomic,strong) UIImageView *imgRecord;
@property (nonatomic,assign) NSInteger nIndex;
@property (nonatomic,strong) NSIndexPath* nsIndexPath;


@end
