//
//  ImageCellTableViewCell.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/11.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageCell;

@protocol RecordCellDelegate <NSObject>

//-(void)realPlayRecordById:(NSInteger)nId;

-(void)addPicView:(ImageCell*)imgCell view:(UIView*)view index:(NSInteger)nIndex;
-(void)addRecordView:(ImageCell*)imgCell view:(UIView*)view index:(NSInteger)nIndex;

@end


@interface ImageCell : UITableViewCell

@property (nonatomic,assign) NSInteger nRow;

@property (nonatomic,strong) NSMutableArray *array;

@property (nonatomic,strong) NSMutableArray *aryImage;

@property (nonatomic,strong) NSMutableDictionary *aryDict;

@property (nonatomic,assign) id<RecordCellDelegate> delegate;

@property (nonatomic,assign) BOOL bDel;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
-(void)setArrayInfo:(NSArray*)array record:(NSArray*)aryRecord;
-(void)freshCell;

@end

