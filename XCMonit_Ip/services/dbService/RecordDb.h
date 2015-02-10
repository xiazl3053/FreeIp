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
@end
