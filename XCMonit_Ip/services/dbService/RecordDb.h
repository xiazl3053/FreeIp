//
//  RecordDb.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/30.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RecordModel;

@interface RecordDb : NSObject



+(BOOL)insertRecord:(RecordModel *)reocrdInfo;
+(NSArray*)queryRecord:(NSString*)strNO;
+(BOOL)deleteRecord:(NSArray *)array;
+(NSArray*)queryRecordByTime:(NSString*)strTime;
+(RecordModel*)queryRecordById:(NSInteger)nIndex;
+(NSArray*)queryAllRecord;
//+(NSArray*)queryRecordByTimeSE:(NSString*)strStartTime endTime:(NSString*)strEndTime no:(NSString*)strNO;
+(NSArray*)queryRtsp:(NSString*)strPath name:(NSString*)strDevName;


+(BOOL)initRecordInfo;

+(NSArray*)queryRtspByTimeSE:(NSString*)strPath name:(NSString*)strDevName start:(NSString*)strStartTime endTime:(NSString*)strEndTime;

+(NSArray*)queryRecordByTimeSE:(NSString*)strStartTime end:(NSString*)strEndTime;

+(NSArray*)queryRecordByTimeSEAndNO:(NSString*)strStartTime endTime:(NSString*)strEndTime no:(NSString*)strNO;

@end
