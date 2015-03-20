




#import <Foundation/Foundation.h>
#import "IDecodeSource.h"


@interface PTPSource : IDecodeSource

@property (nonatomic,assign) NSInteger nChannel;
@property (nonatomic,assign) BOOL nSwitchcode;

-(id)initWithNO:(NSString *)strNO channel:(int)nChannel codeType:(int)nType;
/**
 *  建立连接
 *
 *  @param strSource NO或者其他内容
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
/**
 *  获取码流方式
 *  @return   1是P2P,2是转发
 */
-(int)getSource;
-(void)releaseDecode;
-(void)switchP2PCode:(int)nCode;
@end