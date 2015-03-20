//
//  NewLoginService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/6.
//  Copyright (c) 2015年 夏钟林. All rights reservedmp.
//
#import "LoginInfo.h"
#import "NewLoginService.h"
#import "UserInfo.h"
#import "DecodeJson.h"
@implementation NewLoginService


-(void)reciveHttp:(NSURLResponse *)response data:(NSData *)data error:(NSError *)connectionError
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
                    DLog(@"新增的输出:%d",[array[0] intValue]);
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
        }else{
            if (_httpBlock) {
                _httpBlock(nil,-2);
            }
        }
    } else {
        //登录失败,提示
        if (_httpBlock)
        {
            _httpBlock(nil,-2);
        }
        DLog(@"服务器返回信息错误,%li",(long)responseCode);
    }
   
}

-(void)requestLogin:(NSString *)strUser pwd:(NSString *)strPassword
{

    [UserInfo sharedUserInfo].strUser = strUser;
    [UserInfo sharedUserInfo].strPwd = strPassword;
    NSString *strMD5 = [DecodeJson XCmdMd5String:strPassword];
    [UserInfo sharedUserInfo].strMd5 = strMD5;

    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=login/login/PhoneLogin&user_name=%@&password=%@",XCLocalized(@"httpserver"),[strUser stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],strMD5];
    DLog(@"strUrl:%@",strUrl);
    [self sendRequest:strUrl];
}


@end
