//
//  PlayViewController.h
//  XCMonit_Ip
//  单路视频
//  Created by 夏钟林 on 15/3/10.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XLDecoderServiceImpl.h"
#import "VideoTopHud.h"
#import "VideoDownHud.h"

@interface PlayViewController : UIViewController

@property (nonatomic,assign) BOOL bPlaying;
@property (nonatomic,strong) XLDecoderServiceImpl *decodeImpl;
@property (nonatomic,strong) NSMutableArray *videoFrame;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) VideoDownHud *downHUD;
@property (nonatomic,strong) VideoTopHud *topHUD;

@property (nonatomic,assign) BOOL bDecoding;

-(void)hudViewCreate;

-(id)initWithNO:(NSString*)nsNO name:(NSString*)strName format:(NSUInteger)nFormat;

-(void)startPlay;

@end
