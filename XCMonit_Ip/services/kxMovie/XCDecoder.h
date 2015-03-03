//
//  XCDecoder.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-13.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "DecoderPublic.h"

@interface XCDecoder : NSObject

typedef BOOL(^KxMovieDecoderInterruptCallback)();

typedef int (^XCReadData)(void *opaque, uint8_t *buf, int buf_size);

//视频宽
@property (readonly, nonatomic) NSUInteger frameWidth;
//视频高
@property (readonly, nonatomic) NSUInteger frameHeight;
//解码数据标志，当为yes的时候，发送通知
@property (readonly) BOOL isEOF;
//解码信息初始化标志
@property (readonly) BOOL bIsDecoding;
//视频的fps信息
@property (nonatomic, nonatomic) CGFloat fps;
//当前进度
@property (readwrite,nonatomic) CGFloat position;
//总长度,用于播放录像文件
@property (readwrite, nonatomic) CGFloat duration;
//总时长
@property (nonatomic,assign) CGFloat allTime;
//码流切换
@property (nonatomic,assign) BOOL nSwitchcode;
//文件在手机中的路径
@property (readonly, nonatomic, strong) NSString *path;
//YUV或者RGB
@property (nonatomic) KxVideoFrameFormat videoFrameFormat;
//初始化
/*
    param 1:序列号
    param 2:播放类型，分为转发与P2P方式，默认P2P与转发并行 
    param 3:默认RGB
    param 4:码流：主与辅
 */
-(id)initWithNO:(NSString *)strNO format:(NSUInteger)nFormat videoFormat:(KxVideoFrameFormat)type codeType:(NSInteger)nType;
//初始化
/*
     param 1:序列号
     param 2:播放类型，分为转发与P2P方式，默认P2P与转发并行
     param 3:默认RGB
 */
-(id)initWithNO:(NSString *)strNO format:(NSUInteger)nFormat videoFormat:(KxVideoFrameFormat)type;
//设置解码显示：yuv或者rgb
-(BOOL)setupVideoFrameFormat:(KxVideoFrameFormat) format;
//解码
-(NSMutableArray*)decodeFrames;
//抓拍
-(UIImage *)capturePhoto;
//退出
-(BOOL)getExit;
//销毁P2Psdk
-(void)destorySDK;
//释放P2P一些标志
-(void)releaseDecode;
//录像开始
-(void)recordStart:(NSString*)strPath name:(NSString*)strDevName;
//录像结束
-(void)recordStop;
//录像播放
-(id)initWithPath:(NSString*)strPath;
//解析
- (BOOL) openDecoder: (NSString *) path
               error: (NSError **) perror;

//视频码流切换
-(void)switchP2PCode:(int)nCode;
//设置超时时间，已停用
-(void)setTimeOut:(int)nTime;
//获取码流连接方式:P2P与转发
-(int)getRealType;
//云台控制
-(void)ptz_control:(int)nPtz;
//录像  解码
-(NSMutableArray*)record_decodeFrames;


@end
