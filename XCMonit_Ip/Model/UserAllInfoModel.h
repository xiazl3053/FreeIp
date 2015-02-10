//
//  UserAllInfoModel.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/15.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserAllInfoModel : NSObject


@property (nonatomic,assign) NSInteger nId;
@property (nonatomic,assign) NSInteger str;
@property (nonatomic,strong) NSString *strMobile;//手机
@property (nonatomic,strong) NSString *strEmail;//邮箱
@property (nonatomic,strong) NSString *strUserName;//账号
@property (nonatomic,strong) NSString *strFile;//文件名
@property (nonatomic,strong) NSString *strName;//名字
@property (nonatomic,strong) NSString *strOnlyName;//昵称
@property (nonatomic,strong) NSString *strLastInfo;//最后一次登录信息
@property (nonatomic,assign) NSInteger iProNumber;//省行政编号
@property (nonatomic,assign) NSInteger iCountNumber;//市行政编号

-(id)initWithItems:(NSArray*)items;

@end
