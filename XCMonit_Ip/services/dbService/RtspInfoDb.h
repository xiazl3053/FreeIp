//
//  RtspInfoDb.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RtspInfo;
@interface RtspInfoDb : NSObject


+(BOOL)addRtsp:(RtspInfo*)rtspInfo;

+(NSMutableArray*)queryAllRtsp;
+(BOOL)removeByIndex:(NSInteger)nIndex;
+(BOOL)updateRtsp:(RtspInfo*)rtspInfo;

@end
