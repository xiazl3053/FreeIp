//
//  RegisterAuthCode.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/3.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RegisterAuthCode.h"

@implementation RegisterAuthCode


-(void)requestAuthCode
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=login/login/CaptchaSession",XCLocalized(@"httpserver")];
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block RegisterAuthCode *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
        ^(NSURLResponse* response, NSData* data, NSError* connectionError){
             RegisterAuthCode *strongLogin = weakSelf;
            if (strongLogin) {
                [strongLogin reciveAuthCode:response data:data error:connectionError];
             }
        }];
}

-(void)reciveAuthCode:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
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
                if (array)
                {
                    if(_httpBlock)
                    {
                        _httpBlock(array[1],1);
                    }
                }
                else
                {
                    if(_httpBlock)
                    {
                        _httpBlock(nil,0);
                    }
                }
            }
        }
    }
    else
    {
        if(_httpBlock)
        {
            _httpBlock(nil,-1);
        }
    }
}
-(void)requestRegister:(NSString*)strUser pwd:(NSString*)strPwd auth:(NSString *)strAuth code:(NSString *)strCodeImg
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=login/login/PhoneSignupAdd&captchacheck=%@&captcha=%@&user_name=%@&pwd=%@",XCLocalized(@"httpserver"),strCodeImg,strAuth,strUser,strPwd];
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block RegisterAuthCode *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         RegisterAuthCode *strongLogin = weakSelf;
         if (strongLogin) {
             [strongLogin reciveAuthReg:response data:data error:connectionError];
         }
     }];
    
}

-(void)reciveAuthReg:(NSURLResponse*)response data:(NSData*)data error:(NSError*)connectionError
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
                if (array && array.count >= 4)
                {
                    if(_httpReg)
                    {
                        _httpReg([array[0] intValue]);
                    }
                }
                else
                {
                    if(_httpReg)
                    {
                        _httpReg(0);
                    }
                }
            }
        }
    }
    else
    {
        if(_httpReg)
        {
            _httpReg(-999);
        }
    }
}

-(void)requestAuthUsername:(NSString *)strUser
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=login/login/CheckUserName&user_name=%@",XCLocalized(@"httpserver"),strUser];
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block RegisterAuthCode *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         [weakSelf reciveAuthUser:response data:data error:connectionError];
     }];
}

-(void)reciveAuthUser:(NSURLResponse*)response data:(NSData*)data error:(NSError*)connectionError
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
                if (array)
                {
                    if([array[0] isEqualToString:@"1"])
                    {
                        if(_httpAuthBlock)
                        {
                            _httpAuthBlock(1);
                        }
                    }
                    else
                    {
                        if(_httpAuthBlock)
                        {
                            _httpAuthBlock(0);
                        }
                    }
                }
                else
                {
                    if(_httpAuthBlock)
                    {
                        _httpAuthBlock(0);
                    }
                }
            }
        }
    }
    else
    {
        if(_httpAuthBlock)
        {
            _httpAuthBlock(-1);
        }
    }
}

-(void)reciveAuthImg:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
{
    
}






@end
