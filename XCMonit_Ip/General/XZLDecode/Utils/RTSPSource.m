



#import "RTSPSource.h"


@implementation RTSPSource


/**
 *  建立连接
 *
 *  @param strSource NO或者其他内容
 *
 *  @return
 */
-(BOOL)connection:(NSString*)strSource
{
    return NO;
}

/**
 *  获取下一帧码流
 *
 *  @return
 */
-(NSData*)getNextFrame
{
    return  nil;
}
/**
 *    消息推送
 */
-(void)sendMessage
{
    
}
/**
 *  资源释放
 */
-(void)destorySource
{
    
}

@end