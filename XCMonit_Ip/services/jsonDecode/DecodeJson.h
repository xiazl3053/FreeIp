//
//  XCDecodeJson.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/10.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DecodeJson : NSObject

+(NSString*) decryptUseDES:(NSString*)cipherText key:(NSString*)key;
+(NSString*) XCmdMd5String:(NSString *)str;
+(BOOL) validateEmail: (NSString *) candidate;

+(NSString*)getDeviceTypeByType:(int)nType;

@end
