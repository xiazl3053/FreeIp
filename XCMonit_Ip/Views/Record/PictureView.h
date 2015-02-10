//
//  PictureView.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PictureView : UIView

@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) UILabel *lblDev;
@property (nonatomic,strong) UILabel *lblTime;
@property (nonatomic,strong) UIImageView *imgSelect;
@property (nonatomic,copy) NSString *strPath;

@end
