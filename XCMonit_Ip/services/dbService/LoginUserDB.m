//
//  LoginUserDB.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/18.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "LoginUserDB.h"
#import "UserModel.h"
#import "FMDatabase.h"
#import "UtilsMacro.h"

#define kDatabaseLoginPath [kDocumentPath stringByAppendingPathComponent:@"login.db"]
@implementation LoginUserDB

+(FMDatabase*)initDataLogin
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDatabaseLoginPath];
    if(![db open])
    {
        DLog(@"open fail");
    }
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS userInfo (id integer primary key asc autoincrement, username text, pwd text,UNIQUE(username))"];
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS UserSave (username text,save integer,login integer)"];
    return db;
}

+(BOOL)addLoginUser:(UserModel *)userModel
{
    //INSERT OR ignore
//    NSString *strSql = @"INSERT IGNORE INTO userInfo (username,pwd) SELECT username,pwd FROM userInfo where username = ?";
    return NO;
}

@end
