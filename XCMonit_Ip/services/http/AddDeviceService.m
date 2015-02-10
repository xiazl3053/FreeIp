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
#define ADD_DEVICE_URL  @"http://183.57.82.43/ys/index.php?r=service/service/binddevice"
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
                if (_addDeviceBlock)
                {
                    //9842900000001
                    _addDeviceBlock([array[0] intValue]);
                }
            }
            else
            {
                if (_addDeviceBlock)
                {
                    _addDeviceBlock(-1);
                }
            }
        }
        else
        {
            if (_addDeviceBlock)
            {
                _addDeviceBlock(-1);
            }
        }
    }else
    {
        if (_addDeviceBlock) {
            _addDeviceBlock(-999);
        }
    }
}
-(void)requestAddDevice:(NSString*)strNO auth:(NSString*)strAuth
{
    //service/service/binddevice&session_id=e55ek5k41du8j3jf0d3iatsav7&device_id=450691544&device_verify=ABCDEF&device_name=devicexx
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/binddevice&session_id=%@&device_id=%@&device_verify=%@",
                        XCLocalized(@"httpserver"),
                        [UserInfo sharedUserInfo].strSessionId,strNO,strAuth];
    DLog(@"strUrl:%@",strUrl);
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block AddDeviceService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         AddDeviceService *strongLogin = weakSelf;
         if (strongLogin)
         {
             [strongLogin reciveLoginInfo:response data:data error:connectionError];
         }
     }];
}

-(void)queryDeviceIsExits:(NSString*)strNO auth:(NSString*)strAuth
{
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@index.php?r=service/service/getonedevice&session_id=%@&device_id=%@",
                        XCLocalized(@"httpserver"),[UserInfo sharedUserInfo].strSessionId,strNO];
    DLog(@"strUrl:%@",strUrl);
    _strAuth = strAuth;
    _strNO = strNO;
    NSURL *url=[NSURL URLWithString:strUrl];//创建URL
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];//通过URL创建网络请求
    [request setTimeoutInterval:XC_HTTP_TIMEOUT];//设置超时时间
    [request setHTTPMethod:@"POST"];//设置请求方式
    __block AddDeviceService *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* connectionError){
         AddDeviceService *strongLogin = weakSelf;
         if (strongLogin)
         {
             [strongLogin recvDeviceIsExits:response data:data error:connectionError];
         }
     }];
}

-(void)recvDeviceIsExits:(NSURLResponse*) response data:(NSData*)data error:(NSError*)connectionError
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
                if (_addDeviceBlock)
                {
           //         int nStatus = [array[0] integerValue];
                    if (array.count==2)
                    {
                        [self requestAddDevice:_strNO auth:_strAuth];
                    }
                    else if(array.count==4)
                    {
                        if (_addDeviceBlock)
                        {
                            //9842900000001
                            _addDeviceBlock(64);
                        }
                    }
                }
            }
            else
            {
                if (_addDeviceBlock)
                {
                    _addDeviceBlock(-1);
                }
            }
        }
        else
        {
            if (_addDeviceBlock)
            {
                _addDeviceBlock(-1);
            }
        }
    }else
    {
        if (_addDeviceBlock) {
            _addDeviceBlock(-999);
        }
    }
}


@end
