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

@implementation DeviceService

-(void)reciveHttp:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
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
                if ([array[0] isKindOfClass:[NSArray class]])
                {
                        //是否是数组对象
                    DLog(@"是数组");
                    if (array.count>1)
                    {
                        NSUInteger nLength = array.count;
                        for (NSUInteger i=1; i<nLength; i++)
                        {
                            NSArray *arrayDev = [array objectAtIndex:i];
                            if(arrayDev && arrayDev.count>=5)
                            {
                                DeviceInfoModel *devInfoModel = [[DeviceInfoModel alloc] initWithItems:arrayDev];
                                [self authBlock:devInfoModel status:(int)(nLength-1)];
                            }
                        }
                    }
                    else
                    {
                        //设备信息错误
                        [self authBlock:nil status:0];
                    }
                }
                else
                {
                    if (array && array.count == 5)
                    {
                        int nNumber = [array[4] intValue];
                        DLog(@"设备个数:%d",nNumber);
                        if (nNumber==0)
                        {
                            [self authBlock:nil status:0];
                        }
                        else if(nNumber>0)
                        {
                            [self requestDeviceLimit:0 count:nNumber];
                        }
                    }
                    else
                    {
                        [self authBlock:nil status:-1];
                    }
                }
            }
            else
            {
                [self authBlock:nil status:0];
                DLog(@"登录失败，通信指令错误");
            }
        }
        else
        {
            [self authBlock:nil status:-1];
        }
    }
    else
    {
        DLog(@"BUg?");
        //超时
        [self authBlock:nil status:-1];
    }
}

/**
 *  分组请求设备
 *
 *  @param nIndex 起点
 *  @param nCount 个数
 */
-(void)requestDeviceLimit:(int)nIndex count:(int)nCount
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/GetDrviceInfo&session_id=%@&index=%d&count=%d",XCLocalized(@"httpserver"),[UserInfo sharedUserInfo].strSessionId,nIndex,nCount];
    DLog(@"strUrl:%@",strUrl);
    [self sendRequest:strUrl];
  
}

/**
 *  请求设备总数
 */
-(void)queryDeviceNumber
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/GetCountDrvice&session_id=%@",
                        XCLocalized(@"httpserver"),[UserInfo sharedUserInfo].strSessionId];
    [self sendRequest:strUrl];
}

-(void)authBlock:(DeviceInfoModel*)devInfo status:(int)nStatus
{
    if(_httpDeviceBlock)
    {
        _httpDeviceBlock(devInfo,nStatus);
    }
}

//session_id=rte5mqhs1ldg2p487eq4rqevi7
@end
