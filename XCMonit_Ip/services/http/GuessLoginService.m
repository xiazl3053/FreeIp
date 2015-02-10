//
//  GuessLoginService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/11/18.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "GuessLoginService.h"
#import "DecodeJson.h"
#import "UserInfo.h"

@implementation GuessLoginService

-(void)connectionHttpLogin
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=login/login/PhoneGuestLogin",XCLocalized(@"httpserver")];
    DLog(@"strUrl:%@",strUrl);
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block GuessLoginService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         GuessLoginService *strongLogin = weakSelf;
         if (strongLogin) {
             [strongLogin reciveLoginInfo:response data:data error:connectionError];
         }
     }];
}

-(void)reciveLoginInfo:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
{
    NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
    
    if (!connectionError && responseCode == 200) {
        NSString *str=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        //解密后的字符串
        [UserInfo sharedUserInfo].strMd5 = @"b0bcc391cd65614a59eca8b71bcf1419";
        NSString *strDecry = [DecodeJson decryptUseDES:str key:[UserInfo sharedUserInfo].strMd5];
        NSData *jsonData = [strDecry dataUsingEncoding:NSUTF8StringEncoding];
        if(jsonData)
        {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
            if (dic && dic.count>0)
            {
                NSArray *array = [dic objectForKey:@"data"];
                if (_httpGuessBlock)
                {
                    [UserInfo sharedUserInfo].bGuess = YES;
                    
                    [UserInfo sharedUserInfo].strSessionId = array[4];
                    DLog(@"array[4]:%@",array[4]);
                    _httpGuessBlock([array[0] intValue]);
                }
            }
            else
            {
                if (_httpGuessBlock)
                {
                    _httpGuessBlock(-1);
                }
                DLog(@"登录失败，通信指令错误");
            }
        }else{
            if (_httpGuessBlock) {
                _httpGuessBlock(-2);
            }
        }
    } else {
        //登录失败,提示
        if (_httpGuessBlock)
        {
            _httpGuessBlock((int)responseCode);
        }
        DLog(@"服务器返回信息错误,%li",(long)responseCode);
    }
}

@end
