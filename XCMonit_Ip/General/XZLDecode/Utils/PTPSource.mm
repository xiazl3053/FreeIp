


#import "PTPSource.h"
#import "P2PSDKService.h"
#import "XCNotification.h"

#import "P2PInitService.h"
@interface PTPSource()
{
    RecvFile *recv;
    int nconnection;
    BOOL bDestorySDK;
}
@property (nonatomic,assign) BOOL bNotify;
@property (nonatomic,assign) int nNum;
@property (nonatomic,copy) NSString *strNo;
//@property (nonatomic,st)
@property (nonatomic,assign) int nCodeType;
@property (nonatomic,assign) BOOL bP2P;
@property (nonatomic,assign) BOOL bTran;
@end



@implementation PTPSource

-(id)initWithNO:(NSString *)strNO channel:(int)nChannel codeType:(int)nType
{
    self = [super init];
    if (self)
    {
        _strNo = strNO;
        _nChannel = nChannel;
        _nCodeType = nType;
        nconnection = 1;
        _nNum = 0;
        _bNotify = YES;
    }
    
    return self ;
}

-(void)thread_gcd_PTP
{
    __weak PTPSource *__weakSelf = self;
    BOOL bThread = NO;
    __block BOOL __bThread = bThread;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
       BOOL bReturn = recv->threadP2P(__weakSelf.nCodeType);
       if (bReturn)
       {
           __weakSelf.bP2P = YES;
           DLog(@"P2P打洞成功");
           if (__weakSelf.bTran)//close TRAN
           {
               DLog(@"关闭转发");
               recv->closeTran();
           }
           else
           {
               DLog(@"开始P2P接收码流");
               __bThread = YES;
               //sendMessage
               nconnection = 0;
           }
       }
       else
       {
           DLog(@"P2P出现错误");
           __weakSelf.nNum++;
           if (!__weakSelf.bTran)//close TRAN
           {
               DLog(@"tran-p2p fail");
               if (__weakSelf.bNotify)
               {
                   if(__weakSelf.nNum==2)
                   {
                       recv->bDevDisConn = YES;
                       nconnection = -1;
                   }
               }
           }
           else
           {
               DLog(@"等待转发");
           }
       }
    });
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        DLog(@"start trans");
        BOOL bReturn = recv->threadTran(__weakSelf.nCodeType);
        if (bReturn)
        {
               __weakSelf.bTran = YES;
               DLog(@"转发成功");
               //转发
               if (__weakSelf.bP2P)//close TRAN
               {
                   DLog(@"P2P已成功,关闭转发");
                   recv->closeTran();
               }
               else
               {
                   DLog(@"P2P未成功,开始解码");
                   nconnection = 0;
               }
        }
        else
        {
            DLog(@"tran fail");
           __weakSelf.nNum++;
           if (!__weakSelf.bP2P)//close TRAN
           {
               if (__weakSelf.bNotify)
               {
                   if(__weakSelf.nNum==2)
                   {
                       nconnection = -1;
                   }
               }
           }
        }       
    });
}

-(BOOL)createP2PSdk
{
    P2PSDKClient *sdk = [[P2PInitService sharedP2PInitService] getP2PSDK];
    if (!sdk)
    {
        return  NO;
    }
    
    recv = new RecvFile(sdk,0,(int)_nChannel);
//    NSMutableArray *result = [NSMutableArray array];
    return YES;
}


/**
 *  建立连接
 *
 *  @param strSource NO或者其他内容
 *
 *  @return
 */
-(BOOL)connection:(NSString*)strSource
{
    if(![self createP2PSdk])
    {
        return NO;
    }
    recv->peerName = [_strNo UTF8String];
    
    [self thread_gcd_PTP];
    
    while (nconnection)
    {
        if (nconnection==-1)
        {
            DLog(@"??????");
            return NO;
        }
        [NSThread sleepForTimeInterval:0.8f];
    }
    
    return YES;
}

/**
 *  获取下一帧码流
 *
 *  @return
 */
-(NSData*)getNextFrame
{
    if (!recv)
    {
        return nil;
    }
    @synchronized(recv->aryVideo)
    {
        if(recv->aryVideo.count==0)
        {
            return nil;
        }
        NSData *data = [recv->aryVideo objectAtIndex:0];
        [recv->aryVideo removeObjectAtIndex:0];
        return data;
    }
    return nil;
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

-(int)getSource
{
    if (_bP2P)
    {
        return 1;
    }
    else
    {
        return 2;
    }
}
#pragma mark 码流切换
-(void)switchP2PCode:(int)nCode
{
    DLog(@"目标码流:%d",nCode);
    _nSwitchcode = NO;

    __weak PTPSource *__weakSelf = self;
    __block int __nCode = nCode;
    if(recv)
    {
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            BOOL bReturn = recv->swichCode(__nCode);
            if(bReturn)
            {
                __weakSelf.nSwitchcode = YES;
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:NSCONNECT_P2P_FAIL_VC object:XCLocalized(@"switchError")];
            }
        });
    }
    
}
#pragma mark 先一步停止P2P或者转发操作，在dealloc前调用
-(void)releaseDecode
{
    DLog(@"外面改了");
    _bNotify = NO;
    if(recv)
    {
        recv->sendheartinfoflag = NO;
        recv->bDevDisConn = YES;
        recv->bExit = YES;
    }
}
#pragma mark 销毁Decode
-(void)dealloc
{
  //  [self recordStop];
    DLog(@"释放");
    if(recv)
    {
        recv->StopRecv();
        recv = NULL;
    }
    if (bDestorySDK)
    {
        DLog(@"释放");
        [[P2PInitService sharedP2PInitService] setP2PSDKNull];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_SWITCH_TRAN_OPEN_VC object:nil];
}
@end
