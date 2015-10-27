//
//  VIdeoView.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/29.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VideoViewDelegate <NSObject>

-(void)clickView:(id)sender;

-(void)doubleClickVideo:(id)sender;


@end

@interface VideoView : UIView

@property (nonatomic,assign) id<VideoViewDelegate> delegate;
@property (nonatomic,assign) NSInteger nCursel;
@property (nonatomic,strong) UIImageView *imgView;

//
//-(void)addImage;
//-(void)removeImage;
@end
