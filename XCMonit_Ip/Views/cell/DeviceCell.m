//
//  DeviceCell.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-22.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "DeviceCell.h"
#import "UtilsMacro.h"
#import "DevInfoMacro.h"
@interface DeviceCell()
{
    UITapGestureRecognizer *tapGesture;
    
}

@property (nonatomic,strong) UILabel *lblStatusInfo;
@property (nonatomic,strong) UITapGestureRecognizer *recordGesture;
@end

@implementation DeviceCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 45, 45)];
        
    //    _lblStatus = [[UILabel alloc] initWithFrame:CGRectMake(130, 40, 70, 25)];

        _lblDevNO = [[UILabel alloc] initWithFrame:CGRectMake(78, 15, 180, 20)];
        
    //    _lblStatusInfo = [[UILabel alloc] initWithFrame:CGRectMake(70, 40, 60, 25)];//在线状态
    //    UILabel *lblNOTit = [[UILabel alloc] initWithFrame:CGRectMake(70, 2, 60, 25)];
        
        [_lblDevNO setFont:XCFontInfo(16.0)];
    //    [lblNOTit setText:NSLocalizedString(@"devName", "deviceName")];
    //    [lblNOTit setFont:XCFontInfo(12.0)];
        [_lblStatusInfo setFont:XCFontInfo(12.0)];
        
    //    [self.contentView addSubview:lblNOTit];
        [self.contentView addSubview:_lblStatusInfo];
        
        
        [_lblStatus setFont:XCFontInfo(12.0)];
        [self.contentView addSubview:_imgView];
        [self.contentView addSubview:_lblStatus];
        [self.contentView addSubview:_lblDevNO];
        
   //     [_imgView setImage:[UIImage imageNamed:@"device.png"]];
        
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickImage)];
        [_imgView addGestureRecognizer:tapGesture];
        [_imgView setUserInteractionEnabled:YES];
        
       // DLog(@"加入一个设备状态");
        UIView *lineView = [[UIView alloc] initWithFrame:Rect(0, kTableviewCellHeight-1, kScreenWidth, 1)];
        [lineView setBackgroundColor:[UIColor grayColor]];
        [self.contentView addSubview:lineView];
    }
    return self;
}
-(void)setPlayModel
{
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:Rect(260, 10, 30, 30)];
    [self.contentView addSubview:imgView];
    [imgView setImage:[UIImage imageNamed:@"recordImage"]];
    _recordGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recordClick)];
    [imgView addGestureRecognizer:_recordGesture];
    [imgView setUserInteractionEnabled:YES];
}
-(void)recordClick
{
    if (_delegate && [_delegate respondsToSelector:@selector(recordVideo:name:line:)])
    {
        [_delegate recordVideo:_strDevNO name:_strName line:_nStatus];
    }
}
-(void)removeTap
{
    [_imgView setUserInteractionEnabled:NO];
    [tapGesture removeTarget:self action:@selector(clickImage)];
}
- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}
-(void)clickImage
{
    if (_delegate && [_delegate respondsToSelector:@selector(playVideo:name:type:)]) {
        [_delegate playVideo:_strDevNO name:_strName type:_nType];
    }
}

-(void)dealloc
{
    _lblDevNO = nil;
    _lblStatus = nil;
    _lblStatusInfo = nil;
    _imgView = nil;
}

@end
