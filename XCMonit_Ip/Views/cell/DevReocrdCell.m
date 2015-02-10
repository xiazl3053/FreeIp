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
    if (self)
    {
        
        CellForLabel *lblTIme1 = [[CellForLabel alloc] initWithFrame:Rect(70, 5, 60, 15) font:12];
        CellForLabel *lblTIme2 = [[CellForLabel alloc] initWithFrame:Rect(70, 25, 60, 15) font:12];
        CellForLabel *lblTIme3 = [[CellForLabel alloc] initWithFrame:Rect(70, 45, 60, 15) font:12];
        [lblTIme1 setText:XCLocalized(@"startTime")];
        [lblTIme2 setText:XCLocalized(@"endTime")];
        [lblTIme3 setText:XCLocalized(@"allTime")];
        [self.contentView addSubview:lblTIme1];
        [self.contentView addSubview:lblTIme2];
        [self.contentView addSubview:lblTIme3];
        
        _lblStart = [[CellForLabel alloc] initWithFrame:Rect(135, 5, 160, 15) font:12];
        _lblEnd = [[CellForLabel alloc] initWithFrame:Rect(135, 22, 160, 15) font:12];
        _lblTime = [[CellForLabel alloc] initWithFrame:Rect(135, 45, 160, 15) font:12];
        
        _imgView = [[UIImageView alloc] initWithFrame:Rect(5, 3, 60, 60)];
        [self.contentView addSubview:_lblStart];
        [self.contentView addSubview:_lblEnd];
        [self.contentView addSubview:_lblTime];
        [self.contentView addSubview:_imgView];
//        UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, 66-1, kScreenWidth, 1)];
//        [lineView setBackgroundColor:[UIColor grayColor]];
//        [self.contentView addSubview:lineView];
        
//        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tmall_bg_main"]];
        UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 66-1.5, kScreenWidth, 0.5)];
        sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                                 green:198/255.0
                                                  blue:198/255.0
                                                 alpha:1.0];
        UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 66-1, kScreenWidth, 0.5)] ;
        sLine2.backgroundColor = [UIColor whiteColor];
        
        [self.contentView addSubview:sLine1];
        [self.contentView addSubview:sLine2];
        
    }
    return self;
}

- (void)awakeFromNib
{
    
  //  [_imgView setImage:[UIImage imageNamed:@"deviceOff"]];
    
    
}
-(void)setRecordInfo:(RecordModel*)record
{

    [_lblStart setText:record.strStartTime];
    [_lblEnd setText:record.strEndTime];
    
    [_lblTime setText:[NSString stringWithFormat:@"%d",(int)record.allTime]];
    NSString *strDir = [kLibraryPath stringByAppendingPathComponent:@"record"];
    __block NSString *strImg = [strDir stringByAppendingPathComponent:record.imgFile];
    __weak DevReocrdCell *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UIImage *image = [UIImage imageWithContentsOfFile:strImg];
        dispatch_sync(dispatch_get_main_queue(),
        ^{
            [weakSelf.imgView setImage:image];
        });
    });
    
    
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
}

@end
