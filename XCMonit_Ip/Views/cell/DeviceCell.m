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
@property (nonatomic,strong) UIImageView *imgStatus;


@end

@implementation DeviceCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 90, 72)];//115

        _lblDevNO = [[UILabel alloc] initWithFrame:CGRectMake(132, 19, 150, 20)];
        
        _imgStatus = [[UIImageView alloc] initWithFrame:Rect(115, 21, 15, 15)];
        [self.contentView addSubview:_imgStatus];


        
        [_lblDevNO setFont:XCFontInfo(15.0)];
        [_lblStatusInfo setFont:XCFontInfo(12.0)];
        [self.contentView addSubview:_lblStatusInfo];
        
        
        [_lblStatus setFont:XCFontInfo(15.0)];
        [self.contentView addSubview:_imgView];
        [self.contentView addSubview:_lblStatus];
        [self.contentView addSubview:_lblDevNO];
        
        _lblType = [[UILabel alloc] initWithFrame:Rect(115, 19+27.5+15, 180, 15)];
        [_lblType setFont:[UIFont fontWithName:@"Helvetica" size:11.0f]];
        [_lblType setTextColor:[UIColor grayColor]];
        [self.contentView addSubview:_lblType];
        
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickImage)];
        [_imgView addGestureRecognizer:tapGesture];
        [_imgView setUserInteractionEnabled:YES];
        
        UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, kTableviewDeviceCellHeight-1, kScreenWidth, 0.5)];
        sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                                 green:198/255.0
                                                  blue:198/255.0
                                                 alpha:1.0];
        UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, kTableviewDeviceCellHeight-0.5, kScreenWidth, 0.5)] ;
        sLine2.backgroundColor = [UIColor whiteColor];

        [self.contentView addSubview:sLine1];
        [self.contentView addSubview:sLine2];
    }
    return self;
}
-(void)setPlayModel
{
    //79  25  54
    
    UIButton *btnRemote = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnRemote setImage:[UIImage imageNamed:@"remote_cl"] forState:UIControlStateNormal];
    [btnRemote setImage:[UIImage imageNamed:@"reomte_cl_h"] forState:UIControlStateHighlighted];
    [self.contentView addSubview:btnRemote];
    [btnRemote addTarget:self action:@selector(recordClick) forControlEvents:UIControlEventTouchUpInside];
    btnRemote.frame = Rect(kScreenWidth-60, kTableviewDeviceCellHeight/2-22, 44, 44);
}
-(void)recordClick
{
    if (_delegate && [_delegate respondsToSelector:@selector(recordVideo:name:line:)])
    {
        [_delegate recordVideo:_strDevNO name:_strName line:(int)_nStatus];
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

-(void)setDevName:(NSString *)strDevName
{
//    UIFont *font = [UIFont fontWithName:@"Helvetica" size:16.0f];
//    CGSize labelsize = [strDevName sizeWithFont:font constrainedToSize:CGSizeMake(150.f, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
//    [_lblDevNO setText:strDevName];
    NSString *strImage = _nStatus ? @"font_on" : @"font_off";
    [_imgStatus setImage:[UIImage imageNamed:strImage]];
}

-(void)dealloc
{
    _lblDevNO = nil;
    _lblStatus = nil;
    _lblStatusInfo = nil;
    _imgView = nil;
}
//
@end
