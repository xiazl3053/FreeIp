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
            if (dic && dic.count>0) {
                NSArray *array = [dic objectForKey:@"data"];
                [self authBlock:[array[0] intValue]];
            }
            else
            {
                [self authBlock:-1];
            }
        }
        else
        {
            [self authBlock:-1];
        }
    }
    else
    {
        [self authBlock:-999];
    }
}

-(void)requestDelDevInfo:(NSString*)strDevNO auth:(NSString *)strDevAuth
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/breakdevice&session_id=%@&device_id=%@",
                        XCLocalized(@"httpserver"),
                        [UserInfo sharedUserInfo].strSessionId,strDevNO];
    [self sendRequest:strUrl];
}

-(void)authBlock:(int )nStatus
{
    if(_httpDelDevBlock)
    {
        _httpDelDevBlock(nStatus);
    }
}
@end
