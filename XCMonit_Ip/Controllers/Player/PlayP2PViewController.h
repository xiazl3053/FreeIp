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

-(id)initWithNO:(NSString*)nsNO;
-(id)initWithNO:(NSString*)nsNO name:(NSString*)strName format:(NSUInteger)nFormat;

@end
