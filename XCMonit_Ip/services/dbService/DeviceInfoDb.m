//
//  DeviceInfoDb.m
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-21.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import "DeviceInfoDb.h"
#import "FMDatabase.h"
#import "DevModel.h"
#import "UserModel.h"
#import "UtilsMacro.h"


@implementation DeviceInfoDb

+(FMDatabase *)initDatabaseUser
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabasePath];
    if(![db open])
    {
        DLog(@"open fail");
    }
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS userInfo (id integer primary key asc autoincrement, user text, pwd text)"];
    return db;
}
+(FMDatabase *)initDatabaseDev
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabasePath];
    if(![db open])
    {
        DLog(@"open fail");
    }
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS devInfo (id integer primary key asc autoincrement, devName text, devNO text)"];
    
    return db;
}


+(NSArray *)queryAllDevInfo
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    FMDatabase *db= [DeviceInfoDb initDatabaseDev] ;
    FMResultSet *rs=[db executeQuery:@"SELECT * FROM devInfo"];
    while ([rs next]){
        DevModel *devModel = [[DevModel alloc] initWithDev:[rs stringForColumn:@"devName"] devNO:[rs stringForColumn:@"devNO"]];
        devModel.nId = [[rs stringForColumn:@"id"] integerValue];
        [array addObject:devModel];
    }
    return array;
}

+(NSArray *)queryUserInfo
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    FMDatabase *db= [DeviceInfoDb initDatabaseUser];
    FMResultSet *rs=[db executeQuery:@"SELECT * FROM userInfo"];
    while ([rs next]){
        UserModel *userModel = [[UserModel alloc] initWithUser:[rs stringForColumn:@"user"]
                                                           pwd:[rs stringForColumn:@"pwd"]];
        userModel.nId = [[rs stringForColumn:@"id"] integerValue];
        [array addObject:userModel];
    }
    return array;
}
+(BOOL)insertUserInfo:(UserModel *)user
{
    BOOL bReturn = YES;
    NSArray *array = [DeviceInfoDb queryUserInfo];
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabasePath];
    [db open];
    if (array.count>0) {
        NSString *strSql = [[NSString alloc] initWithFormat:@"update userInfo set user = ?, pwd = ?"];
        bReturn = [db executeUpdate:strSql,user.strUser,user.strPwd];

    }else{
        NSString *strSql = [[NSString alloc] initWithFormat:@"insert into userInfo (user,pwd) values (?,?)"];
        bReturn = [db executeUpdate:strSql,user.strUser,user.strPwd];
    }
    
    return  bReturn;
}
+(BOOL)insertDevInfo:(DevModel *)devModel
{
    BOOL bReturn = YES;
    FMDatabase *db = [DeviceInfoDb initDatabaseDev];
    FMResultSet *rs=[db executeQuery:@"select * from devInfo where devNO = ?",devModel.strDevNO];
    if(rs.next)
    {
        bReturn = [db executeUpdate:@"update devInfo set devName = ? where devNO=?",devModel.strDevName,devModel.strDevNO];
    }
    else
    {
        NSString *strSql = [[NSString alloc] initWithFormat:@"insert into devInfo (devName,devNO) values (?,?)"];
        bReturn = [db executeUpdate:strSql,devModel.strDevName,devModel.strDevNO];
        strSql = nil;
    }
    return  bReturn;
}

+(BOOL)deleteDevInfo:(DevModel*)devModel
{
    BOOL bReturn = YES;
    FMDatabase *db = [DeviceInfoDb initDatabaseDev];
    NSString *strSql = [[NSString alloc] initWithFormat:@"delete from devInfo where id=?"];
    bReturn = [db executeUpdate:strSql,[NSNumber numberWithInteger:devModel.nId]];

    return bReturn;
}


@end
