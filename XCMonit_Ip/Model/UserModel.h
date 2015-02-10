//
//  UserModel.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-21.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserModel : NSObject

@property (nonatomic,assign) NSInteger nId;
@property (nonatomic,strong) NSString *strUser;
@property (nonatomic,strong) NSString *strPwd;

-(id)initWithUser:(NSString *)user pwd:(NSString*)pwd;

@end
