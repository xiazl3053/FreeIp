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
#import "FMDatabaseQueue.h"

@implementation DeviceInfoDb

+(FMDatabase *)initDatabaseUser
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabasePath];
    if(![db open])
    {
        DLog(@"open fail");
    }
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS userInfo (id integer primary key asc autoincrement, user text, pwd text)"];
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS UserSave (id integer primary key asc autoincrement,save integer,login integer)"];
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

+(FMDatabase *)initDatabaseUserInfo
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabasePath];
    if(![db open])
    {
        DLog(@"open fail");
    }
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS UserSave (id integer primary key asc autoincrement,save integer,login integer)"];

    return db;
}

+(FMDatabase *)initdataUserRecord
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabaseUserRecord];
    if(![db open])
    {
        DLog(@"open fail");
    }
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS user_record (id integer primary key asc autoincrement,u_id integer)"];
    return db;
}


+(BOOL)querySavePwd
{
    FMDatabase *db= [DeviceInfoDb initDatabaseUserInfo];
    BOOL bReturn = NO;
    NSString *strSql = @"select * from UserSave where id = 1";
    FMResultSet *rs=[db executeQuery:strSql];
    if([rs next])
    {
        NSInteger nCount = [[rs stringForColumn:@"save"] integerValue];
        if (nCount)
        {
            bReturn = YES;
        }
    }
    else
    {
        NSString *strSql1 = @"insert into UserSave (save,login) values (0,0)";
        [db executeUpdate:strSql1];
        bReturn = NO;
    }
    return bReturn;
}

+(BOOL)updateSavePwd:(NSInteger)nSave
{
    FMDatabase *db= [DeviceInfoDb initDatabaseUserInfo];
    NSString *strSql = @"update UserSave set save = ? where id = 1";
    BOOL bFlag = [db executeUpdate:strSql,[[NSNumber alloc] initWithInteger:nSave]];

    return bFlag;
}

+(BOOL)updateLogin:(NSInteger)nLogin
{
    FMDatabase *db= [DeviceInfoDb initDatabaseUserInfo];
    NSString *strSql = @"update UserSave set login = ?  where id = 1";
    BOOL bFlag = [db executeUpdate:strSql,[[NSNumber alloc] initWithInteger:nLogin]];
    return  bFlag;
}

+(BOOL)queryLogin
{
    FMDatabase *db= [DeviceInfoDb initDatabaseUserInfo];
    BOOL bReturn = NO;
    NSString *strSql = @"select * from UserSave where id = 1";
    FMResultSet *rs=[db executeQuery:strSql];
    if([rs next])
    {
        NSInteger nCount = [[rs stringForColumn:@"login"] integerValue];
        if (nCount)
        {
            bReturn = YES;
        }
    }
    else
    {
        NSString *strSql1 = @"insert into UserSave (save,login) values (0,0)";
        [db executeUpdate:strSql1];
        bReturn = NO;
    }
    return bReturn;
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
    NSMutableArray *array = [NSMutableArray array];
    FMDatabase *db= [DeviceInfoDb initdataUserRecord];
    
    FMResultSet *rs = [db executeQuery:@"select * from User_Record"];
    FMDatabase *dbUser = [DeviceInfoDb initDatabaseUser];
    if (rs.next)
    {
        int nId = [[rs stringForColumn:@"u_id"] intValue];
        
        FMResultSet *rs1 = nil;
        
        if (nId==0)
        {
            rs1=[dbUser executeQuery:@"SELECT * FROM userInfo where id = 1"];
        }
        else if(nId==-1)
        {
            rs1=[dbUser executeQuery:@"SELECT * FROM userInfo order by id desc"];
        }
        else
        {
             rs1=[dbUser executeQuery:@"SELECT * FROM userInfo where id = ?",[NSNumber numberWithInt:nId]];
        }
        if(rs1.next)
        {
            UserModel *userModel = [[UserModel alloc] initWithUser:[rs1 stringForColumn:@"user"]
                                                               pwd:[rs1 stringForColumn:@"pwd"]];
            userModel.nId = [[rs stringForColumn:@"id"] integerValue];
            [array addObject:userModel];
        }
    }
    else
    {
        [db executeUpdate:@"insert into User_Record (u_id) values (0)"];
        
        FMResultSet *rs1=[dbUser executeQuery:@"SELECT * FROM userInfo where id = 1"];
        if(rs1.next)
        {
            UserModel *userModel = [[UserModel alloc] initWithUser:[rs1 stringForColumn:@"user"]
                                                               pwd:[rs1 stringForColumn:@"pwd"]];
            userModel.nId = [[rs stringForColumn:@"id"] integerValue];
            [array addObject:userModel];
        }
    }
    [dbUser close];
    [rs close];
    [db close];
    return array;
}
+(BOOL)insertUserInfo:(UserModel *)user
{
    BOOL bReturn = YES;
    
    FMDatabase *db= [DeviceInfoDb initDatabaseUser];
    
    FMDatabase *dbRecord= [DeviceInfoDb initdataUserRecord];
    
    FMResultSet *frs = [db executeQuery:@"select * from userInfo where user = ?",user.strUser];
    if (frs.next)
    {
        //修改
        [db executeUpdate:@"update userInfo set pwd = ? where user = ?",user.strPwd,user.strUser];
        //然后
        int nU_id = [[frs stringForColumn:@"id"] intValue];
        bReturn = [dbRecord executeUpdate:@"update User_Record set u_id = ?",[NSNumber numberWithInt:nU_id]];
    }
    else
    {
        //添加
        [db executeUpdate:@"insert into userInfo (user,pwd) values (?,?)",user.strUser,user.strPwd];
        
        bReturn = [dbRecord executeUpdate:@"update User_Record set u_id = ?",[NSNumber numberWithInt:-1]];
    }
    [frs close];
    [dbRecord close];
    [db close];
    
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
