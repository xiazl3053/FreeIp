//
//  XCAddDeviceService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/13.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "AddDeviceService.h"
#import "UserInfo.h"
#import "DecodeJson.h"

@interface AddDeviceService()
{
    
}
@property (nonatomic,strong) NSString *strNO;
@property (nonatomic,strong) NSString *strAuth;
@end


@implementation AddDeviceService

-(void)requestAddDevice:(NSString*)strNO auth:(NSString*)strAuth
{

    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/binddevice&session_id=%@&device_id=%@&device_verify=%@",
                        kHTTP_Host,
                        [UserInfo sharedUserInfo].strSessionId,strNO,strAuth];
    [self sendRequest:strUrl];
}

-(void)reciveHttp:(NSURLResponse *)response data:(NSData *)data error:(NSError *)connectionError
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
                if (array.count == 2)
                {
                    //设备不存在继续请求
                    [self requestAddDevice:_strNO auth:_strAuth];
                }
                else if(array.count==4)
                {
                    [self authBlock:[array[0] intValue]];
                }
                else
                {
                    [self authBlock:-999];
                }
            }
            else
            {
                [self authBlock:-999];
            }
        }
        else
        {
            [self authBlock:-999];
        }
    }
    else
    {
        if (_addDeviceBlock)
        {
            _addDeviceBlock(-999);
        }
    }   
}

-(void)queryDeviceIsExits:(NSString*)strNO auth:(NSString*)strAuth
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/getonedevice&session_id=%@&device_id=%@",
                        kHTTP_Host,[UserInfo sharedUserInfo].strSessionId,strNO];
    //查询设备是否已经添加
    _strNO = strNO;
    _strAuth = strAuth;
    [self sendRequest:strUrl];
}

-(void)authBlock:(int)nStatus
{
    if(_addDeviceBlock)
    {
        _addDeviceBlock(nStatus);
    }
}

@end
