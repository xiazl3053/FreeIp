//
//  RtspWlanCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/4/9.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "RtspWlanCell.h"

@implementation RtspWlanCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    
    [self initWithBody];
    
    return self;
}

-(void)layoutSubviews
{
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, kScreenWidth, 0.5)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 90.5, kScreenWidth, 0.5)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:sLine1];
    [self.contentView addSubview:sLine2];
}

-(void)initWithBody
{
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 90, 72)];
    
    UIImageView *imgAdd = [[UIImageView alloc] initWithFrame:Rect(kScreenWidth-50, 24, 44, 44)];
    [imgAdd setImage:[UIImage imageNamed:@"WIFI_ADD"]];
    [self.contentView addSubview:imgAdd];
    [imgAdd addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addDevInfo)]];
    [imgAdd setUserInteractionEnabled:YES];
    
    UILabel *lblDevName = [[UILabel alloc] initWithFrame:CGRectMake(115, 19, 150, 20)];
    
    UILabel *lblSource = [[UILabel alloc] initWithFrame:Rect(115, 19+27.5+15, 180, 15)];
    [lblDevName setFont:XCFontInfo(15.0)];
    [lblSource setFont:XCFontInfo(12.0)];
    [lblSource setTextColor:[UIColor grayColor]];
    
    [self.contentView addSubview:imgView];
    [self.contentView addSubview:lblDevName];
    [self.contentView addSubview:lblSource];
    
    imgView.tag = 10001;
    lblDevName.tag = 10002;
    lblSource.tag = 10003;
}

-(void)addDevInfo
{
    if (_delegate && [_delegate respondsToSelector:@selector(addDeviceInfo:)])
    {
        [_delegate addDeviceInfo:_rtsp];
    }
}

-(void)setDevInfo:(RtspInfo*)rtsp
{
    _rtsp = rtsp;
    if([rtsp.strType isEqualToString:@"IPC"])
    {
        [((UIImageView*)[self.contentView viewWithTag:10001]) setImage:[UIImage imageNamed:@"device_ipc"]];
    }
    else
    {
        [((UIImageView*)[self.contentView viewWithTag:10001]) setImage:[UIImage imageNamed:@"device_dvr"]];
    }
    [((UILabel*)[self.contentView viewWithTag:10002]) setText:rtsp.strDevName];
    
    NSString *strSource = [NSString stringWithFormat:@"%@:%d",rtsp.strAddress,(int)rtsp.nPort];
    
    [((UILabel*)[self.contentView viewWithTag:10003]) setText:strSource];
}

@end
