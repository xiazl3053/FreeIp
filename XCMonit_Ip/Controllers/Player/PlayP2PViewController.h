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


//   ps sps pps i
//   ps p
//   1406
//   1406
//   1406
//   1406
//   1406
//   1406
//   ps+sps+pps+I
//   16个ps

//JRTP

//SPS+PPS+I
//60000
//ntemp = 1500
/*
    2   65535
    sps+pps+i > 65535
    FF FF
    send ps send 65535
 
    send ps send sps+pps+i-65535
 70000
    65535
    ps 4465
 
 
    00 00 01
    00 00 01

    
 
 
 
*/


