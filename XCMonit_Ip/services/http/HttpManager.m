//
//  HttpManager.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/6.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "HttpManager.h"

@implementation HttpManager

-(void)sendRequest:(NSString *)strPath
{
    NSURL *url=[NSURL URLWithString:strPath];
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block HttpManager *weakSelf = self;
    DLog(@"strUrl:%@",strPath);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         HttpManager *strongLogin = weakSelf;
         if (strongLogin)
         {
             [strongLogin reciveHttp:response data:data error:connectionError];
         }
     }];
}


-(void)reciveHttp:(NSURLResponse *)response data:(NSData*)data error:(NSError*)connectionError
{
    
}

@end
