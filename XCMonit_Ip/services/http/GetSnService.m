//
//  GetSnService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/7/20.
//  Copyright © 2015年 夏钟林. All rights reserved.
//

#import "GetSnService.h"
#import "UserInfo.h"
@implementation GetSnService



-(void)requestSn:(NSString *)strDevice
{
    NSString *strUrl = [NSString stringWithFormat:@"%@/index.php?r=login/login/getSnInfo&session_id=%@",XCLocalized(@"httpserver"),[UserInfo sharedUserInfo].strSessionId];
    
    
    [self sendRequest:strUrl];
}

-(void)reciveHttp:(NSURLResponse *)response data:(NSData *)data error:(NSError *)connectionError
{
    NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
    
    if (!connectionError && responseCode == 200)
    {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (dic && dic.count > 0)
        {
            NSArray *array = [dic objectForKey:@"data"];
            if (array)
            {
                if (array.count==4)
                {
                    //错误
                    if (_getSnInfo) {
                        _getSnInfo([array[0] intValue],0);
                    }
                }
                else if(array.count ==2 )
                {
                    NSArray *ary = array[1];
                    if (_getSnInfo)
                    {
                        _getSnInfo(1,[ary[2] intValue]);
                    }
                }
            }
        }
        else
        {
            if (_getSnInfo)
            {
                _getSnInfo(0,0);
            }
        }
    }
    else
    {
        if (_getSnInfo)
        {
            _getSnInfo(responseCode,0);
        }
    }
}





@end
