//
//  ISource.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/3/11.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface IDecodeSource : NSObject
/**
 *  建立连接
 *
 *  @param strSource NO或者其他内容  保留  在子类中建立一个初始化，实现传值操作
 *
 *  @return
 */
-(BOOL)connection:(NSString*)strSource;
/**
 *  获取下一帧码流
 *
 *  @return
 */
-(NSData*)getNextFrame;
/**
 *    消息推送
 */
-(void)sendMessage;
/**
 *  资源释放
 */
-(void)destorySource;

@end