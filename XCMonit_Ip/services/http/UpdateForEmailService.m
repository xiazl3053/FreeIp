//
//  UpdateForEmailService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/11/14.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "UpdateForEmailService.h"
#import "DecodeJson.h"
#import "UserInfo.h"

@implementation UpdateForEmailService

DEFINE_SINGLETON_FOR_CLASS(UpdateForEmailService);

/*
 邮箱修改密码请求
 strPwd:用户密码
 strCode:验证码
 触发回调函数
 */
-(void)requestUpdForEmail:(NSString *)strPwd code:(NSString*)strCode
{
    NSString *strNewPwd = [DecodeJson XCmdMd5String:strPwd];
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=login/login/CaptchaUpdatePwd&language=en&user_name=%@&pwd=%@&code=%@&session_id=%@"
                        ,XCLocalized(@"httpserver"),[UserInfo sharedUserInfo].strUser,strNewPwd,strCode,[UserInfo sharedUserInfo].strSessionId];
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block UpdateForEmailService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         UpdateForEmailService *strongLogin = weakSelf;
         if (strongLogin)
         {
             [strongLogin recvUpdStatus:response data:data error:connectionError];
         }
     }];
    
}

-(void)recvUpdStatus:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
{
    NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
    
    if (!connectionError && responseCode == 200)
    {
        if(data)
        {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            if (dic && dic.count>0)
            {
                NSArray *array = [dic objectForKey:@"data"];
                if (_httpAuthCode)
                {
                    _httpUpdPwd([array[0] intValue]);
                    
                }
            }
            else
            {
                if (_httpUpdPwd)
                {
                    _httpUpdPwd(999);
                }
                DLog(@"登录失败，通信指令错误");
            }
        }
        else
        {
            if (_httpUpdPwd)
            {
                _httpUpdPwd(999);
            }
        }
    }
    else
    {
        if (_httpUpdPwd)
        {
            _httpUpdPwd((int)responseCode);
        }
        DLog(@"responseCode:%li",(long)responseCode);
    }
}

/*
 通过邮箱获取验证码
 strEmail:用户邮箱
 */
-(void)requestAuthCode:(NSString*)strEmail
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=login/login/SendEmail&user_name=%@&language=en"
                        ,XCLocalized(@"httpserver"),strEmail];
    [UserInfo sharedUserInfo].strUser = strEmail;
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block UpdateForEmailService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         UpdateForEmailService *strongLogin = weakSelf;
         if (strongLogin)
         {
             [strongLogin recvAuthCode:response data:data error:connectionError];
         }
     }];
}

-(void)recvAuthCode:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
{
    NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
    
    if (!connectionError && responseCode == 200)
    {
        //解密后的字符串
        if(data)
        {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            if (dic && dic.count>0)
            {
                NSArray *array = [dic objectForKey:@"data"];
                if (_httpAuthCode)
                {
                    int nStatus = [array[0] intValue];
                    if(nStatus==1)
                    {
                        [UserInfo sharedUserInfo].strSessionId = array[4];
                        [UserInfo sharedUserInfo].strEmail = array[1];
                        DLog(@"[UserInfo sharedUserInfo].strUser:%@",[UserInfo sharedUserInfo].strUser);
                    }
                    _httpAuthCode([array[0] intValue]);
                }
            }
            else
            {
                if (_httpAuthCode)
                {
                    _httpAuthCode(999);
                }
                DLog(@"登录失败，通信指令错误");
            }
        }else{
            if (_httpAuthCode)
            {
                _httpAuthCode(999);
            }
        }
    }
    else
    {
        if (_httpAuthCode)
        {
            _httpAuthCode((int)responseCode);
        }
        DLog(@"responseCode:%li",(long)responseCode);
    }
}

@end
