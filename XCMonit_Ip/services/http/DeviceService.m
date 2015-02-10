//
//  DeviceService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/11.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//
#import "UserInfo.h"
#import "DeviceService.h"
#import "DecodeJson.h"
#import "DeviceInfoModel.h"

#define GET_DEVICE_URL   @"http://183.57.82.43/ys/index.php?r=service/service/GetDrviceInfo"
@implementation DeviceService

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
                if (array.count>1) {
                    NSUInteger nLength = array.count;
                    for (NSUInteger i=1; i<nLength; i++)
                    {
                        NSArray *arrayDev = [array objectAtIndex:i];
                        if(arrayDev && arrayDev.count>=5)
                        {
                            DeviceInfoModel *devInfoModel = [[DeviceInfoModel alloc] initWithItems:arrayDev];
                            _httpDeviceBlock(devInfoModel,nLength-1);
                        }
                    }
                }else
                {
                    //设备信息错误
                    if (_httpDeviceBlock)
                    {
                        _httpDeviceBlock(nil,0);
                    }
                }
            }
            else
            {
                if (_httpDeviceBlock)
                {
                    _httpDeviceBlock(nil,0);
                }
                DLog(@"登录失败，通信指令错误");
            }
        }else
        {
            //解码失败
            if (_httpDeviceBlock)
            {
                _httpDeviceBlock(nil,-1);
            }
        }
    } else {
        //超时
        if (_httpDeviceBlock)
        {
            _httpDeviceBlock(nil,-1);
        }
    }
}


-(void)requestDeviceLimit:(int)nIndex count:(int)nCount
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/GetDrviceInfo&session_id=%@&index=%d&count=%d",XCLocalized(@"httpserver"),[UserInfo sharedUserInfo].strSessionId,nIndex,nCount];
    DLog(@"strUrl:%@",strUrl);
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block DeviceService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         DeviceService *strongLogin = weakSelf;
         if (strongLogin)
         {
             [strongLogin reciveLoginInfo:response data:data error:connectionError];
         }
     }];
}

-(void)queryDeviceNumber
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/GetCountDrvice&session_id=%@",
                        XCLocalized(@"httpserver"),[UserInfo sharedUserInfo].strSessionId];
    DLog(@"strUrl:%@",strUrl);
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block DeviceService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         DeviceService *strongLogin = weakSelf;
         if (strongLogin)
         {
             [strongLogin recviceNumber:response data:data error:connectionError];
         }
     }];
}

-(void)recviceNumber:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
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
                if (array && array.count == 5)
                {
                    int nNumber = [array[4] intValue];
                    DLog(@"设备个数:%d",nNumber);
                    if (nNumber>=0)
                    {
                        [self requestDeviceLimit:0 count:nNumber];
                    }
                }
            }
        }
        else
        {
            if (_httpDeviceBlock) {
                _httpDeviceBlock(nil,-999);
            }
        }

    }
    else
    {
        if (_httpDeviceBlock) {
            _httpDeviceBlock(nil,0);
        }
    }
}

-(void)queryDevice:(int)nCount
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/GetCountDrvice&session_id=%@",
                        XCLocalized(@"httpserver"),[UserInfo sharedUserInfo].strSessionId];
    DLog(@"strUrl:%@",strUrl);
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block DeviceService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         DeviceService *strongLogin = weakSelf;
         if (strongLogin) {
             [strongLogin reciveLoginInfo:response data:data error:connectionError];
         }
     }];
}


//session_id=rte5mqhs1ldg2p487eq4rqevi7
@end
