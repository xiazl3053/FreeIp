//
//  RecordDb.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/30.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RecordDb.h"
#import "UtilsMacro.h"
#import "FMDatabase.h"
#import "RecordModel.h"
@implementation RecordDb

+(BOOL)initRecordInfo
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabaseRecord];
    if(![db open])
    {
        DLog(@"open fail");
        //应用错误   重新安装
        return NO;
    }
#if 0
    NSString *strInfo = @"drop table recordInfo";
    [db executeUpdate:strInfo];
#endif
#if 1
    NSString *strInfo = @"SELECT * FROM sqlite_master WHERE type='table' AND name='recordInfo'";
    FMResultSet *rs = [db executeQuery:strInfo];
    if (rs.next)
    {
        //如果有   不做任何操作
        DLog(@"有");

    }
    else
    {
        //如果没有这个表，先创建
        [db beginTransaction];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS recordInfo (id integer primary key asc autoincrement,devNo text,file text,imgfile text, startTIme timestamp,endTime timestamp,allTime integer,devName text,frameNums integer,frameTimes integer)"];
        //查询有没有record表
        NSString *strInfo = @"SELECT count(*) FROM sqlite_master WHERE type='table' AND name='record'";
        FMResultSet *rs = [db executeQuery:strInfo];
        if (rs.next)
        {
            //如果有，执行查询，并且插入数据，最终删除
            NSString *strInsert = @"insert into recordInfo select id,devNo,file,imgfile,startTIme,endTime,allTime,devName,0,0 from record";
            [db executeUpdate:strInsert];
            
        }
        [db commit];
    }
    [db close];
#endif
    return YES;
}


+(FMDatabase *)initDatabaseRecord
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabaseRecord];
    if(![db open])
    {
        DLog(@"open fail");
    }

    return db;
}

+(BOOL)insertRecord:(RecordModel *)recordInfo
{
    BOOL bReturn = NO;
    
    FMDatabase *db = [RecordDb initDatabaseRecord];//frameNums integer,frameTimes integer
    NSString *strSql = @"insert into recordInfo (devNo,startTIme,endTime,file,imgfile,allTime,devName,frameNums,frameTimes) values (?,?,?,?,?,?,?,?,?)";
    [db beginTransaction];
    bReturn = [db executeUpdate:strSql,recordInfo.strDevNO,recordInfo.strStartTime,recordInfo.strEndTime,recordInfo.strFile,recordInfo.imgFile,[NSNumber numberWithInteger:recordInfo.allTime],recordInfo.strDevName,[NSNumber numberWithInteger:recordInfo.nFramesNum],[NSNumber numberWithInteger:recordInfo.nFrameBit]];
    [db commit];
    [db close];
    return bReturn;
}

#pragma mark 根据序列号查询纪录
+(NSArray*)queryRecord:(NSString*)strNO
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from recordInfo where devNo = ? order by startTIme"];
    FMDatabase *db = [RecordDb initDatabaseRecord];
    FMResultSet *rs = [db executeQuery:strSql,strNO];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devNo"],[rs stringForColumn:@"startTIme"],[rs stringForColumn:@"endTime"],
                        [rs stringForColumn:@"file"],[rs stringForColumn:@"imgfile"],[rs stringForColumn:@"alltime"],
                          [rs stringForColumn:@"devName"],nil];
        RecordModel *recordModel = [[RecordModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    [db close];
    return arrayTable;
}

#pragma mark 抓拍数据查询
+(NSArray*)queryRecordByTime:(NSString*)strTime
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from recordInfo where starttime > ? and starttime < ? order by startTIme desc"];
    FMDatabase *db = [RecordDb initDatabaseRecord];
    NSString *strStartTime = [NSString stringWithFormat:@"%@ 00:00:00",strTime];
    NSString *strEndTime = [NSString stringWithFormat:@"%@ 23:59:59",strTime];
    FMResultSet *rs = [db executeQuery:strSql,strStartTime,strEndTime];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devNo"],
                          [rs stringForColumn:@"startTIme"],[rs stringForColumn:@"endTime"],
                          [rs stringForColumn:@"file"],[rs stringForColumn:@"imgfile"],[rs stringForColumn:@"alltime"],
                          [rs stringForColumn:@"devName"],nil];
        RecordModel *recordModel = [[RecordModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    [db close];
    return arrayTable;
}


#pragma mark 
+(NSArray*)queryAllRecord
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from recordInfo order by startTIme desc"];
    FMDatabase *db = [RecordDb initDatabaseRecord];
    FMResultSet *rs = [db executeQuery:strSql];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devNo"],
                          [rs stringForColumn:@"startTIme"],[rs stringForColumn:@"endTime"],
                          [rs stringForColumn:@"file"],[rs stringForColumn:@"imgfile"],[rs stringForColumn:@"alltime"],
                          [rs stringForColumn:@"devName"],nil];
        RecordModel *recordModel = [[RecordModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    [db close];
    return arrayTable;
}
#pragma mark 所有录像查询
+(NSArray*)queryRecordByTimeSE:(NSString*)strStartTime end:(NSString*)strEndTime
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from recordInfo where starttime > ? and starttime < ? order by startTIme desc"];
    FMDatabase *db = [RecordDb initDatabaseRecord];
    NSString *strNewS = [NSString stringWithFormat:@"%@ 00:00:00",strStartTime];
    NSString *strNewE = [NSString stringWithFormat:@"%@ 23:59:59",strEndTime];
    FMResultSet *rs = [db executeQuery:strSql,strNewS,strNewE];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devNo"],
                          [rs stringForColumn:@"startTIme"],[rs stringForColumn:@"endTime"],
                          [rs stringForColumn:@"file"],[rs stringForColumn:@"imgfile"],[rs stringForColumn:@"alltime"],
                          [rs stringForColumn:@"devName"],nil];
        RecordModel *recordModel = [[RecordModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    [db close];
    return arrayTable;
}

#pragma mark 录像纪录起始、序列号查询
+(NSArray*)queryRecordByTimeSEAndNO:(NSString*)strStartTime endTime:(NSString*)strEndTime no:(NSString*)strNO
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from recordInfo where starttime > ? and starttime < ? and devNo = ? order by startTIme desc"];
    FMDatabase *db = [RecordDb initDatabaseRecord];
    NSString *strNewS = [NSString stringWithFormat:@"%@ 00:00:00",strStartTime];
    NSString *strNewE = [NSString stringWithFormat:@"%@ 23:59:59",strEndTime];
    FMResultSet *rs = [db executeQuery:strSql,strNewS,strNewE,strNO];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devNo"],
                          [rs stringForColumn:@"startTIme"],[rs stringForColumn:@"endTime"],
                          [rs stringForColumn:@"file"],[rs stringForColumn:@"imgfile"],[rs stringForColumn:@"alltime"],
                          [rs stringForColumn:@"devName"],nil];
        RecordModel *recordModel = [[RecordModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    [db close];
    return arrayTable;
}

+(NSArray*)queryRtsp:(NSString*)strPath name:(NSString*)strDevName
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from recordInfo where devName = ? and devNo like ? order by startTIme desc"];
    FMDatabase *db = [RecordDb initDatabaseRecord];
  //  NSString *strLike = [NSString stringWithFormat:@"%@%%",strPath];//％％转意符
    NSString *strLike = [NSString stringWithFormat:@"%@%%",strPath];
    FMResultSet *rs = [db executeQuery:strSql,strDevName,strLike];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devNo"],
                          [rs stringForColumn:@"startTIme"],[rs stringForColumn:@"endTime"],
                          [rs stringForColumn:@"file"],[rs stringForColumn:@"imgfile"],[rs stringForColumn:@"alltime"],
                          [rs stringForColumn:@"devName"],nil];
        RecordModel *recordModel = [[RecordModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    [db close];
    return arrayTable;
}
+(NSArray*)queryRtspByTimeSE:(NSString*)strPath name:(NSString*)strDevName start:(NSString*)strStartTime endTime:(NSString*)strEndTime
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from recordInfo where devName = ? and devNo = ? and starttime > ? and starttime < ? order by startTIme desc"];
    FMDatabase *db = [RecordDb initDatabaseRecord];
 //   NSString *strLike = [NSString stringWithFormat:@"%%%@%%",strPath];
    NSString *strNewS = [NSString stringWithFormat:@"%@ 00:00:00",strStartTime];
    NSString *strNewE = [NSString stringWithFormat:@"%@ 23:59:59",strEndTime];
    FMResultSet *rs = [db executeQuery:strSql,strDevName,strPath,strNewS,strNewE];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devNo"],
                          [rs stringForColumn:@"startTIme"],[rs stringForColumn:@"endTime"],
                          [rs stringForColumn:@"file"],[rs stringForColumn:@"imgfile"],[rs stringForColumn:@"alltime"],
                          [rs stringForColumn:@"devName"],nil];
        RecordModel *recordModel = [[RecordModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    [db close];
    return arrayTable;
}

+(BOOL)deleteRecord:(NSArray *)array
{
    FMDatabase *db = [RecordDb initDatabaseRecord];
    for (RecordModel *record  in array)
    {
        NSString *strSql = @"delete from recordInfo where file = ?";
        if([db executeUpdate:strSql,record.strFile])
        {
            DLog(@"删除一条记录");
            NSString *strPath = [NSString stringWithFormat:@"%@/record/%@",kLibraryPath,record.strFile];
           
            if ([[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:strPath] error:nil]) {
                DLog(@"删除一个文件");
            }
            NSString *strImgPath = [NSString stringWithFormat:@"%@/record/%@",kLibraryPath,record.imgFile];
            if ([[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:strImgPath] error:nil])
            {
                DLog(@"删除一个文件");
            }
        }
    }
    [db close];
    return YES;
}

+(RecordModel*)queryRecordById:(NSInteger)nIndex
{
    FMDatabase *db = [RecordDb initDatabaseRecord];
    NSString *strSql = [NSString stringWithFormat:@"select * from recordInfo where id = ?"];
    FMResultSet *rs = [db executeQuery:strSql,[[NSNumber alloc] initWithInteger:nIndex]];
    if (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devNo"],
                          [rs stringForColumn:@"startTIme"],[rs stringForColumn:@"endTime"],
                          [rs stringForColumn:@"file"],[rs stringForColumn:@"imgfile"],[rs stringForColumn:@"alltime"],
                          [rs stringForColumn:@"devName"],nil];
        RecordModel *recordModel = [[RecordModel alloc] initWithItems:array];
        //frameNums integer,frameTimes integer
        DLog(@"frameNums:%li---frameTimes:%li",(long)[[rs stringForColumn:@"frameNums"] integerValue],(long)[[rs stringForColumn:@"frameTimes"] integerValue]);
        recordModel.nFramesNum = [[rs stringForColumn:@"frameNums"] integerValue];
        recordModel.nFrameBit = [[rs stringForColumn:@"frameTimes"] integerValue];
        [db close];
        return recordModel;
    }
    [db close];
    return nil;
}

@end
