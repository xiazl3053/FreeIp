//
//  XCAddDeviceService.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/13.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^HttpAddDeviceBlock)(int nStatus);
@interface AddDeviceService : NSObject

@property (nonatomic,copy) HttpAddDeviceBlock addDeviceBlock;

-(void)requestAddDevice:(NSString*)strNO auth:(NSString*)strAuth;

-(void)queryDeviceIsExits:(NSString*)strNO auth:(NSString*)strAuth;

@end
