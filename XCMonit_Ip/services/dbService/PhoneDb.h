//
//  PhoneDb.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/25.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PictureModel;
@interface PhoneDb : NSObject

+(BOOL)insertRecord:(PictureModel *)pic;

+(NSArray*)queryRecord:(NSString*)strTime end:(NSString*)strEndTime;
+(NSArray*)queryLastRecord;

+(BOOL)deleteRecord:(NSArray *)array;
+(BOOL)deleteRecordById:(NSInteger)nId;
+(NSString*)queryLastTime;
+(NSArray*)queryRecordByTime:(NSString*)strTime;
+(NSArray*)queryAllPhone;

+(NSArray*)queryPicByTimeSE:(NSString*)strStartTime end:(NSString*)strEndTime;
+(PictureModel *)queryPicByIndex:(NSInteger)nIndex;

@end
