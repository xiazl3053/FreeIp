 //
//  UpdNameService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/20.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "UpdNameService.h"
#import "UserInfo.h"
#import "DecodeJson.h"

@implementation UpdNameService



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
                if (_httpBlock) {
                    _httpBlock([array[0] intValue]);
                }
            }
            else
            {
                if (_httpBlock)
                {
                    _httpBlock(-1);
                }
            }
        }
        else
        {
            if (_httpBlock)
            {
                _httpBlock(-2);
            }
        }
    }
    else
    {
        if (_httpBlock)
        {
            _httpBlock(-2);
        }
    }
}
-(void)requestUpdName:(NSString*)strDevNO name:(NSString *)strDevName
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/updatedevice&session_id=%@&device_id=%@&new_device_name=%@",XCLocalized(@"httpserver"),
                        [UserInfo sharedUserInfo].strSessionId,strDevNO,[strDevName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [self sendRequest:strUrl];
}



@end
