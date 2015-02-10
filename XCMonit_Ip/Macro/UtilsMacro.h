//
//  UtilsMacro.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-19.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#ifndef XCMonit_Ip_UtilsMacro_h
#define XCMonit_Ip_UtilsMacro_h

#define UIColorFromRGB(r,g,b) [UIColor \
colorWithRed:r/255.0 \
green:g/255.0 \
blue:b/255.0 alpha:1]

#define UIColorFromRGBA(r,g,b,a) [UIColor \
colorWithRed:r/255.0 \
green:g/255.0 \
blue:b/255.0 alpha:a]

#define NSStringFromInt(intValue) [NSString stringWithFormat:@"%d",intValue]
#define NSStringFromFloat(floatValue) [NSString stringWithFormat:@"%f",floatValue]


enum connectP2P
{
    CONNECT_NO_ERROR = 0 ,
    CONNECT_P2P_SERVER,
    CONNECT_DEV_ERROR
};

#define  kTableviewCellHeight   59 
#define  kTableViewRTSPCellHeight   59




#define DEFINE_SINGLETON_FOR_HEADER(className) \
\
+ (className *)shared##className;

#define DEFINE_SINGLETON_FOR_CLASS(className) \
\
+ (className *)shared##className { \
    static className *shared##className = nil; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        shared##className = [[self alloc] init]; \
    }); \
    return shared##className; \
}

#define kNSCachesPath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define kDocumentPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kDatabasePath [kDocumentPath stringByAppendingPathComponent:@"xc.db"]
#define kDatabaseRecord [kDocumentPath stringByAppendingPathComponent:@"record.db"]
#define kDatabaseRTSP [kDocumentPath stringByAppendingPathComponent:@"rtsp.db"]
#define kLibraryPath  [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kLibaryShoto [kLibraryPath stringByAppendingPathComponent:@"shoto"]
#define IOS_SYSTEM_8 [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0


#endif
