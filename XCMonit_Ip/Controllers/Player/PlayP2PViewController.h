//
//  XCPlayerController.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-14.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayP2PViewController : UIViewController

@property (readonly) BOOL playing;

/**
 *  初始化方法
 *
 *  @param nsNO    设备序列号
 *  @param strName 设备名
 *  @param nFormat 视频数据显示方式
 *
 *  @return self
 */
-(id)initWithNO:(NSString*)nsNO name:(NSString*)strName format:(NSUInteger)nFormat;



@end
