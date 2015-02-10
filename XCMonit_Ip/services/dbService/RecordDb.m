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

+(FMDatabase *)initDatabaseRecord
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabaseRecord];
    if(![db open])
    {
        DLog(@"open fail");
    }
    //1.id   devNo  startTIme endTime
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS record (id integer primary key asc autoincrement,devNo text,file text, startTIme timestamp,endTime timestamp,allTime integer)"];
    return db;
}
+(BOOL)insertRecord:(RecordModel *)reocrdInfo
{
    BOOL bReturn = NO;
    
    FMDatabase *db = [RecordDb initDatabaseRecord];
    NSString *strSql = [[NSString alloc] initWithFormat:@"insert into record (devNo,startTIme,endTime,file,allTime) values (?,?,?,?,?)"];
    bReturn = [db executeUpdate:strSql,reocrdInfo.strDevNO,reocrdInfo.strStartTime,reocrdInfo.strEndTime,reocrdInfo.strFile,[NSNumber numberWithInteger:reocrdInfo.allTime]];
    
    return bReturn;
}
+(NSArray*)queryRecord:(NSString*)strNO
{
    NSMutableArray *arrayTable = [NSMutableArray array];
    NSString *strSql = [NSString stringWithFormat:@"select * from record where devNo = ?"];
    FMDatabase *db = [RecordDb initDatabaseRecord];
    FMResultSet *rs = [db executeQuery:strSql,strNO];
    while (rs.next)
    {
        NSArray *array = [[NSArray alloc] initWithObjects:[rs stringForColumn:@"id"],[rs stringForColumn:@"devNo"],[rs stringForColumn:@"startTIme"],
                                                          [rs stringForColumn:@"endTime"],[rs stringForColumn:@"file"],[rs stringForColumn:@"alltime"],nil];
        RecordModel *recordModel = [[RecordModel alloc] initWithItems:array];
        [arrayTable addObject:recordModel];
    }
    return arrayTable;
}
+(BOOL)deleteRecord:(NSArray *)array
{
    FMDatabase *db = [RecordDb initDatabaseRecord];
    for (RecordModel *record  in array)
    {
        NSString *strSql = @"delete from record where file = ?";
        if([db executeUpdate:strSql,record.strFile])
        {
            DLog(@"删除一条记录");
            NSString *strPath = [NSString stringWithFormat:@"%@/record/%@",kLibraryPath,record.strFile];
           
            if ([[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:strPath] error:nil]) {
                DLog(@"删除一个文件");
            }
        }
    }
    return YES;
}


@end
