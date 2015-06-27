//
//  XCLoginService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/10.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "LoginService.h"
#import "DecodeJson.h"
#import "LoginInfo.h"
#import "UserInfo.h"

#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>


@implementation LoginService

-(id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(void)reciveHttp:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
{
    NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
    
    if (!connectionError && responseCode == 200) {
        NSString *str=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        //解密后的字符串
        NSString *strDecry = [DecodeJson decryptUseDES:str key:[UserInfo sharedUserInfo].strMd5];
        NSData *jsonData = [strDecry dataUsingEncoding:NSUTF8StringEncoding];
        if(jsonData)
        {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
            if (dic && dic.count>0)
            {
                NSArray *array = [dic objectForKey:@"data"];
                LoginInfo *loginInfo = [[LoginInfo alloc] initWidthItem:array];
                [UserInfo sharedUserInfo].strSessionId = loginInfo.strLoginId;
                if (_httpBlock)
                {
                    [UserInfo sharedUserInfo].bGuess = NO;
                    _httpBlock(loginInfo,[array[0] intValue]);
                }
            }
            else
            {
                if (_httpBlock)
                {
                    _httpBlock(nil,-1);
                }
                DLog(@"登录失败，通信指令错误");
            }
        }else
        {
            if (_httpBlock) {
                _httpBlock(nil,-2);
            }
        }
    }
    else
    {
        //登录失败,提示
        if (_httpBlock)
        {
            _httpBlock(nil,-2);
        }
        DLog(@"服务器返回信息错误,%li",(long)responseCode);
    }
}

-(void)connectionHttpLogin:(NSString *)strUser pwd:(NSString*)strPwd
{
    [UserInfo sharedUserInfo].strUser = strUser;
    [UserInfo sharedUserInfo].strPwd = strPwd;
    NSString *strMD5 = [DecodeJson XCmdMd5String:strPwd];
    [UserInfo sharedUserInfo].strMd5 = strMD5;
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=login/login/PhoneLogin&user_name=%@&password=%@",kHTTP_Host,[strUser stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],strMD5];
    DLog(@"strUrl:%@",strUrl);
    [self sendRequest:strUrl];
}

-(void)dealloc
{
    
}
@end
