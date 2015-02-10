//
//  PTZView.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/12/8.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PTZViewDelegate;
@class PTZButton;
@interface PTZView : UIView

// 7 个按钮

@property (nonatomic,strong) PTZButton *btnRight;
@property (nonatomic,strong) PTZButton *btnLeft;
@property (nonatomic,strong) PTZButton *btnUp;
@property (nonatomic,strong) PTZButton *btnDown;
@property (nonatomic,strong) PTZButton *btnZoomIn;
@property (nonatomic,strong) PTZButton *btnZoomOut;
@property (nonatomic,assign) id<PTZViewDelegate> delegate;


@end

@interface PTZButton : UIButton

@property (nonatomic,assign) int nStart;
@property (nonatomic,assign) int nStop;

-(instancetype)initCreateButton:(NSString *)strImage high:(NSString*)strHigh start:(int)nStart stop:(int)nStop;

@end

@protocol PTZViewDelegate<NSObject>

@optional

-(void)ptzView:(int)ptzCmd;

@end


