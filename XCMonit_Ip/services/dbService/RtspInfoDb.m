//
//  RtspInfoDb.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RtspInfoDb.h"
#import "FMDatabase.h"
#import "DevModel.h"
#import "UserModel.h"
#import "RtspInfo.h"
#import "UtilsMacro.h"
@implementation RtspInfoDb

+(FMDatabase *)initDatabaseRtsp
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabaseRTSP];
    if(![db open])
    {
        DLog(@"open fail");
    }
    //1.id   devNo  startTIme endTime
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS rtsp (id integer primary key asc autoincrement,devName text,user text, pwd text,address text,port integer,type text,channel integer)"];
    return db;
}

+(BOOL)addRtsp:(RtspInfo*)rtspInfo
{
    FMDatabase *db = [RtspInfoDb initDatabaseRtsp];
    BOOL bReturn = NO;
    //  insert into rtsp (devName,address,port,user,pwd,type,channel) values(?,?,?,?,?,?,?)
    NSString *strSql = @"insert into rtsp (devName,address,port,user,pwd,type,channel) values(?,?,?,?,?,?,?)";
    bReturn = [db executeUpdate:strSql,rtspInfo.strDevName,rtspInfo.strAddress,[[NSNumber alloc] initWithInteger:rtspInfo.nPort],rtspInfo.strUser,rtspInfo.strPwd,rtspInfo.strType,[[NSNumber alloc] initWithInteger:rtspInfo.nChannel]];
    return bReturn;
}

+(NSMutableArray*)queryAllRtsp
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    FMDatabase *db = [RtspInfoDb initDatabaseRtsp];
    NSString *strSql = @"select * from rtsp";
    FMResultSet *rs = [db executeQuery:strSql];
    while (rs.next)
    {
        NSArray *items = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devName"],[rs stringForColumn:@"user"],
                          [rs stringForColumn:@"pwd"],[rs stringForColumn:@"address"],[rs stringForColumn:@"port"],
                          [rs stringForColumn:@"type"],[rs stringForColumn:@"channel"],nil];
        RtspInfo *info = [[RtspInfo alloc] initWithItems:items];
        [array addObject:info];
    }
    return  array;
}
+(BOOL)removeByIndex:(NSInteger)nIndex
{
    FMDatabase *db = [RtspInfoDb initDatabaseRtsp];
    NSString *strSql = @"delete from rtsp where id = ?";
    return [db executeUpdate:strSql,[[NSNumber alloc] initWithInteger:nIndex]];
}
+(BOOL)updateRtsp:(RtspInfo*)rtspInfo
{
    FMDatabase *db = [RtspInfoDb initDatabaseRtsp];
    
    NSString *strSql = @"update rtsp set devName = ? , user = ? , pwd =? , address = ? , port = ? , channel = ?  where id = ?";
    
    return [db executeUpdate:strSql,rtspInfo.strDevName,rtspInfo.strUser,rtspInfo.strPwd,rtspInfo.strAddress,[[NSNumber alloc] initWithInteger:rtspInfo.nPort],
                            [[NSNumber alloc] initWithInteger:rtspInfo.nChannel],[[NSNumber alloc] initWithInteger:rtspInfo.nId]];
}
@end
