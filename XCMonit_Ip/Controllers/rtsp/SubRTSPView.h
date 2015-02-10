//
//  SubCateViewController.h
//  top100
//
//  Created by Dai Cloud on 12-7-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SubRTSPDelegate <NSObject>

@optional
-(void)playRtspConnect:(NSInteger)nChannel;

@end

@interface SubRTSPView : UIView

@property (nonatomic,assign) NSInteger nCount;
@property (nonatomic,assign) id<SubRTSPDelegate> delegate;

@end
