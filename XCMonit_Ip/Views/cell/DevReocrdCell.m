//
//  DevReocrdCellTableViewCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/30.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "DevReocrdCell.h"
#import "UtilsMacro.h"
#import "CellForLabel.h"
#import "RecordModel.h"
@interface DevReocrdCell()
{
    
}
@property (nonatomic,strong) CellForLabel *lblStart;
@property (nonatomic,strong) CellForLabel *lblEnd;
@property (nonatomic,strong) CellForLabel *lblTime;

@end

@implementation DevReocrdCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib
{
    
    CellForLabel *lblTIme1 = [[CellForLabel alloc] initWithFrame:Rect(70, 5, 60, 15) font:12];
    CellForLabel *lblTIme2 = [[CellForLabel alloc] initWithFrame:Rect(70, 25, 60, 15) font:12];
    CellForLabel *lblTIme3 = [[CellForLabel alloc] initWithFrame:Rect(70, 45, 60, 15) font:12];
    [lblTIme1 setText:@"开始时间"];
    [lblTIme2 setText:@"结束时间"];
    [lblTIme3 setText:@"总 时 间"];
    [self.contentView addSubview:lblTIme1];
    [self.contentView addSubview:lblTIme2];
    [self.contentView addSubview:lblTIme3];
    
    _lblStart = [[CellForLabel alloc] initWithFrame:Rect(135, 5, 160, 15) font:12];
    _lblEnd = [[CellForLabel alloc] initWithFrame:Rect(135, 22, 160, 15) font:12];
    _lblTime = [[CellForLabel alloc] initWithFrame:Rect(135, 45, 160, 15) font:12];
    
    _imgView = [[UIImageView alloc] initWithFrame:Rect(5, 8, 45, 45)];
    [self.contentView addSubview:_lblStart];
    [self.contentView addSubview:_lblEnd];
    [self.contentView addSubview:_lblTime];
    [self.contentView addSubview:_imgView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, 62, kScreenWidth, 1)];
    [lineView setBackgroundColor:[UIColor grayColor]];
    [self.contentView addSubview:lineView];
  //  [_imgView setImage:[UIImage imageNamed:@"deviceOff"]];
    
    
}
-(void)setRecordInfo:(RecordModel*)record
{
    [_lblStart setText:record.strStartTime];
    [_lblEnd setText:record.strEndTime];
    
    [_lblTime setText:[NSString stringWithFormat:@"%d",record.allTime]];
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
}

@end
