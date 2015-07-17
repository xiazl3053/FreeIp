//
//  PhoneDb.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/25.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "PhoneDb.h"
#import "Picture.h"
#import "UtilsMacro.h"
#import "FMDatabase.h"
@implementation PhoneDb

+(FMDatabase *)initDatabaseRecord
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabaseRecord];
    if(![db open])
    {
        DLog(@"open fail");
    }
    //1.id   devNo  startTIme endTime
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS picture (id integer primary key asc autoincrement,devName text,file text, startTIme timestamp)"];
    return db;
}




#pragma mark 抓拍数据插入
+(BOOL)insertRecord:(PictureModel *)pic
{
    BOOL bReturn = NO;
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    NSString *strSql = [[NSString alloc] initWithFormat:@"insert into picture (devName,startTIme,file) values (?,?,?)"];
    bReturn = [db executeUpdate:strSql,pic.strDevName,pic.strTime,pic.strFile];
    return bReturn;
}
#pragma mark 抓拍数据删除
+(BOOL)deleteRecord:(NSArray *)array
{
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    for (PictureModel *picture  in array)
    {
        NSString *strSql = @"delete from picture where file = ? ";
        if([db executeUpdate:strSql,picture.strFile])
        {
            DLog(@"删除一条记录");
            NSString *strPath = [NSString stringWithFormat:@"%@/shoto/%@/%@",kLibraryPath,picture.strTime,picture.strFile];
            if ([[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:strPath] error:nil])
            {
                DLog(@"删除一个文件");
            }
        }
    }
    return YES;
}
+(PictureModel *)queryPicByIndex:(NSInteger)nIndex
{
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    NSString *strSql = @"select * from picture where id = ? order by id desc";
    NSNumber *number= [[NSNumber alloc] initWithInteger:nIndex];
    FMResultSet *rs = [db executeQuery:strSql,number];
    if (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devName"],[rs stringForColumn:@"startTIme"],[rs stringForColumn:@"file"],nil];
        PictureModel *recordModel = [[PictureModel alloc] initWithItems:array];
        return recordModel;
    }
    return nil;
}

+(BOOL)deleteRecordById:(NSInteger)nId
{
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    NSString *strSql = @"delete from picture where id = ?";
    if([db executeUpdate:strSql,[NSNumber numberWithInteger:nId]])
    {
        return YES;
    }
    
    return NO;
}
#pragma mark 根据起始时间查询

+(NSArray*)queryPicByTimeSE:(NSString*)strStartTime end:(NSString*)strEndTime
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from picture where startTIme >= ? and startTime <= ? order by id desc"];
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    NSString *strNewS = [NSString stringWithFormat:@"%@ 00:00:00",strStartTime];
    NSString *strNewE = [NSString stringWithFormat:@"%@ 23:59:59",strEndTime];
    FMResultSet *rs = [db executeQuery:strSql,strNewS,strNewE];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devName"],[rs stringForColumn:@"startTIme"],[rs stringForColumn:@"file"],nil];
        PictureModel *recordModel = [[PictureModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    return arrayTable;
}


#pragma mark 抓拍数据查询
+(NSArray*)queryRecordByTime:(NSString*)strTime
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from picture where startTIme >= ? and startTime <= ? order by id desc"];
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    FMResultSet *rs = [db executeQuery:strSql,strTime,strTime];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devName"],[rs stringForColumn:@"startTIme"],[rs stringForColumn:@"file"],nil];
        PictureModel *recordModel = [[PictureModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    return arrayTable;
}


+(NSArray*)queryRecord:(NSString*)strTime end:(NSString*)strEndTime
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from picture where startTIme > ? and startTIme < ? order by id desc"];
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    FMResultSet *rs = [db executeQuery:strSql,strTime,strEndTime];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devName"],[rs stringForColumn:@"startTIme"],[rs stringForColumn:@"file"],nil];
        PictureModel *recordModel = [[PictureModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    return arrayTable;
}
+(NSArray*)queryLastRecord
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    
    //select top 10 * from [table] where sid=1 order by id desc
    NSString *strSql1 = @"select * from picture order by startTIme desc limit 1";//select * from user order by id desc limit 1
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    FMResultSet *rs = [db executeQuery:strSql1];
    if (rs.next)
    {
        NSString *strTime = [rs stringForColumn:@"startTIme"];
        NSString *strSql2 = @"select * from picture where startTIme >= ?"; 
        FMResultSet *rs1 = [db executeQuery:strSql2,strTime];
        while (rs1.next)
        {
            NSArray *array = [[NSArray alloc] initWithObjects:[rs1 stringForColumn:@"id"],[rs1 stringForColumn:@"devName"],[rs1 stringForColumn:@"startTIme"],[rs1 stringForColumn:@"file"],nil];
            PictureModel *recordModel = [[PictureModel alloc] initWithItems:array];
            [arrayTable addObject:recordModel];
        }
        return arrayTable;
    }
    else
    {
        return arrayTable;
    }
    return arrayTable;
}
+(NSString*)queryLastTime
{
    NSString *strSql1 = @"select * from picture order by startTIme desc limit 1";//select * from user order by id desc limit 1
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    FMResultSet *rs1 = [db executeQuery:strSql1];
    NSDateFormatter *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
    NSDate *time1 = nil;
    if (rs1.next)
    {
        time1 = [fileformatter dateFromString:[rs1 stringForColumn:@"startTIme"]];
    }
    else
    {
        time1 = [fileformatter dateFromString:@"2016-01-01"];
    }
    NSString *strSql2 = @"select * from recordInfo order by startTIme desc limit 1";
    FMResultSet *rs2 = [db executeQuery:strSql2];
    NSDate *time2 = nil;
    if (rs2.next)
    {
        NSString *strTime = [rs2 stringForColumn:@"startTIme"];
        time2 = [fileformatter dateFromString:strTime];
    }
    else
    {
        time2 = [fileformatter dateFromString:@"2016-01-01"];
    }
    [fileformatter setDateFormat:@"YYYY-MM-dd"];
    if([time1 timeIntervalSinceNow]>=[time2 timeIntervalSinceNow])
    {
        return [fileformatter stringFromDate:time2];
    }
    else
    {
        return [fileformatter stringFromDate:time1];
    }
    return @"null";
}

+(NSArray*)queryAllPhone
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql1 = @"select * from picture order by id desc";
    FMDatabase *db = [PhoneDb initDatabaseRecord];
    FMResultSet *rs = [db executeQuery:strSql1];
    while(rs.next)
    {
            NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devName"],[rs stringForColumn:@"startTIme"],[rs stringForColumn:@"file"],nil];
        if (array.count==4)
        {
            PictureModel *recordModel = [[PictureModel alloc] initWithItems:array];
            [arrayTable addObject:recordModel];
        }
    }
    return arrayTable;
}


@end
