//
//  DeleteDevService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/13.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "DeleteDevService.h"
#import "DecodeJson.h"
#import "UserInfo.h"

@implementation DeleteDevService
#define DEL_DEVICE_URL  @"http://183.57.82.43/ys/index.php?r=service/service/breakdevice"
-(void)reciveLoginInfo:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
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
            if (dic && dic.count>0) {
                NSArray *array = [dic objectForKey:@"data"];
                if (_httpDelDevBlock) {
                    _httpDelDevBlock([array[0] intValue]);
                }
            }
            else
            {
                if (_httpDelDevBlock)
                {
                    _httpDelDevBlock(-1);
                }
            }
        }
        else
        {
            if (_httpDelDevBlock)
            {
                _httpDelDevBlock(-1);
            }
        }
    }
    else{
        if (_httpDelDevBlock)
        {
            _httpDelDevBlock(-999);
        }
    }
}
-(void)requestDelDevInfo:(NSString*)strDevNO auth:(NSString *)strDevAuth
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/breakdevice&session_id=%@&device_id=%@",NSLocalizedString(@"httpserver","http service"),
                        [UserInfo sharedUserInfo].strSessionId,strDevNO];
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:10];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block DeleteDevService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         DeleteDevService *strongLogin = weakSelf;
         if (strongLogin) {
             [strongLogin reciveLoginInfo:response data:data error:connectionError];
         }
     }];
}

@end
