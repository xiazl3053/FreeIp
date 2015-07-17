//
//  LoginSNService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/7/17.
//  Copyright © 2015年 夏钟林. All rights reserved.
//

#import "LoginSNService.h"
#import "DecodeJson.h"
#import "UserInfo.h"

@interface LoginSNService()
{
    
}
@property (nonatomic,copy) NSString *strUser;
@property (nonatomic,copy) NSString *strPwd;
@property (nonatomic,copy) NSString *strSN;

@end

@implementation LoginSNService

-(void)reciveHttp:(NSURLResponse *)response data:(NSData *)data error:(NSError *)connectionError
{
    NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
    
    if (!connectionError && responseCode == 200)
    {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (dic && dic.count > 0)
        {
            NSArray *array = [dic objectForKey:@"data"];
            if (array && array.count == 1)
            {
                [UserInfo sharedUserInfo].strSessionId = array[0];
                [self requestAuth];
            }
            else if(array.count == 4 )
            {
                if (_sn_login)
                {
                    _sn_login([array[0] intValue]);
                }
            }
            else
            {
                DLog(@"通信错误");
                if (_sn_login)
                {
                    _sn_login(0);
                }
            }
        }
        else
        {
            if (_sn_login)
            {
                _sn_login(0);
            }
        }
    }
    else
    {
        if (_sn_login)
        {
            _sn_login(0);
        }
    }
}

-(void)requestAuth
{
    NSString *strMD5 = [DecodeJson XCmdMd5String:_strPwd];
    [UserInfo sharedUserInfo].strMd5 = strMD5;
    
    NSString *strUrl = [NSString stringWithFormat:@"%@index.php?r=login/login/snlogin&session_id=%@&device_id=%@&local_user=%@&local_pwd=%@",SN_HTTP_HOST,[UserInfo sharedUserInfo].strSessionId
            ,_strSN,_strUser,_strPwd];
    
    [self sendRequest:strUrl];
}

-(void)requestLoginSN:(NSString *)strUser pwd:(NSString *)strPwd sn:(NSString *)strSN
{
    _strUser = strUser;
    _strPwd = strPwd;
    _strSN = strSN;
    [self requestMd5];
}

-(void)requestMd5
{
    NSString *strUrl = [NSString stringWithFormat:@"%@index.php?r=login/login/GetSnCheckCode",SN_HTTP_HOST];
    
    [self sendRequest:strUrl];
    
}





@end
