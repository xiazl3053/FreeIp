//
//  VersionCheckService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/4/27.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "VersionCheckService.h"

#import "DecodeJson.h"

#import "UserInfo.h"

@implementation VersionCheckService


-(void)requestVersion
{
    NSString *strUrl = [NSString stringWithFormat:@"%@index.php?r=login/login/AppVersion",XCLocalized(@"httpserver")];
    [self sendRequest:strUrl];
}


-(void)reciveHttp:(NSURLResponse *)response data:(NSData *)data error:(NSError *)connectionError
{
    NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
    
    if (!connectionError && responseCode == 200)
    {
        NSString *str=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        //解密后的字符串
        NSString *strDecry = [DecodeJson decryptUseDES:str key:[UserInfo sharedUserInfo].strMd5];
        [self authBlock:strDecry];
    }
    else
    {
        [self authBlock:nil];
        DLog(@"检测版本超时");
    }
}

-(void)authBlock:(NSString *)nStatus
{
    if (_httpBlock)
    {
        _httpBlock(nStatus);
    }
}


@end
