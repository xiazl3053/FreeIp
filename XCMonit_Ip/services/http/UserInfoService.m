//
//  UserInfoService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "UserInfoService.h"
#import "UserInfo.h"
#import "DecodeJson.h"


@implementation UserInfoService

#define USER_INFO_SERVICE_URL  @"http://183.57.82.43/ys/index.php?r=service/service/getuserinfo"

-(void)reciveLoginInfo:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
{
    NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
    if (!connectionError && responseCode == 200)
    {
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
                if(array.count==2)
                {
                    UserAllInfoModel *userAll = [[UserAllInfoModel alloc] initWithItems:array[1]];
                    if (_httpBlock)
                    {
                    
                        _httpBlock(userAll,1);
                    }
                }
                else
                {
                    if (_httpBlock)//信息错误
                    {
                        _httpBlock(nil,0);
                    }
                }
            }
            else
            {
                if (_httpBlock)
                {
                    _httpBlock(nil,0);
                }
            }
        }
        else
        {
            if (_httpBlock)
            {
                _httpBlock(nil,2);
            }
        }
    }
    else
    {
        if (_httpBlock)
        {
            _httpBlock(nil,999);
        }
    }
}
-(void)requestUserInfo
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@&session_id=%@",USER_INFO_SERVICE_URL,[UserInfo sharedUserInfo].strSessionId];
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:3];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block UserInfoService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         UserInfoService *strongLogin = weakSelf;
         if (strongLogin) {
             [strongLogin reciveLoginInfo:response data:data error:connectionError];
         }
     }];
}

@end
