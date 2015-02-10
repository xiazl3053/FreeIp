//
//  P2PInitService.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/18.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "P2PInitService.h"
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>

extern "C"
{
    #include "libavformat/avformat.h"
    #include "libswscale/swscale.h"
}


#define  TO_MP4  1


typedef struct FFMPEG_DECODER{
    int				streamNumber;
    uint8_t			streamFormat[8];
    uint32_t		videoWidth;
    uint32_t		videoHeight;
    AVFormatContext *pFormatCtx;
    AVFrame         *pFrame;
    AVCodecContext  *pCodecCtx;
    
 //   sem_t 			sem_ffmpeg;
    int 			decodeErrTimes;
    bool			decodeSuccess;
    
    uint8_t 		*yuvDataBuf;
    
    uint8_t			*buf;    //ffmpeg buffer
    pthread_mutex_t buffer_lock;
    uint8_t			haveNewData;
 //   sem_t  			decodeSignal;
    
    
    uint32_t		frameDuration;  	// 1/30 = 0.03333 (S) * 1000000 = 33333(us)
    uint32_t		srcframeDuration;  	// 1/30 = 0.03333 (S) * 1000000 = 33333(us)
    struct timeval  lastSysFrameTime;  //last system frame time
    
    
    
    uint32_t 		curframeNum;
    uint32_t		frameRate;
    pthread_mutex_t frameNumLock;
    
    uint8_t			rtspPauseFlag;
    uint8_t 		rtspPlayFlag;
    
    
    
    
#if TO_MP4
    int				videoStream;
    AVFormatContext* pOutFormatCtx;
    
    AVStream *pOutStream;
    AVStream *pInStream;
    int64_t	istNextPts;
    int64_t	istNextDts;
    int64_t	istPts,istDts;
    uint32_t firstSaw;
#endif

}FFMPEG_DECODER;


static FFMPEG_DECODER *myDecodeInit(const char *mInputFileName,const char *mOutputFileName){
    AVInputFormat* pAvinputFmt = NULL;
  //  AVCodec         *pCodec = NULL;
    int             i;
    AVIOContext * pb = NULL;
    FFMPEG_DECODER *ffmpegDecoder = NULL;
    
    ffmpegDecoder = (FFMPEG_DECODER*)malloc(sizeof(FFMPEG_DECODER));
    if(!ffmpegDecoder)
        return NULL;
    ffmpegDecoder->pFormatCtx = NULL;
    ffmpegDecoder->pOutFormatCtx = NULL;
    ffmpegDecoder->videoStream = -1;
    ffmpegDecoder->pCodecCtx = NULL;
    ffmpegDecoder->pOutStream = NULL;
    ffmpegDecoder->pInStream = NULL;
    ffmpegDecoder->pFormatCtx  = avformat_alloc_context();
    
#if  TO_MP4
    avformat_alloc_output_context2(&ffmpegDecoder->pOutFormatCtx, NULL, NULL,mOutputFileName);
#endif
    if( avformat_open_input(&ffmpegDecoder->pFormatCtx, mInputFileName, pAvinputFmt, NULL) != 0 )
    {
        
        goto REALEASE_avformat_open_input;
    }
    
    //sem_wait(&gResource.g_decoder_open_signal);
    //锁
    if( avformat_find_stream_info(ffmpegDecoder->pFormatCtx, NULL ) < 0 ){
        goto REALEASE_avformat_find_stream_info;
    }
    //sem_post(&gResource.g_decoder_open_signal);

    for ( i = 0; i < ffmpegDecoder->pFormatCtx->nb_streams; i++)
    {
        if (ffmpegDecoder->pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            ffmpegDecoder->videoStream = i;
            break;
        }
    }
    
    if(ffmpegDecoder->videoStream == -1 ){
        goto REALEASE_avformat_find_stream_info;
    }
    ffmpegDecoder->pInStream = ffmpegDecoder->pFormatCtx->streams[ffmpegDecoder->videoStream];
    ffmpegDecoder->pCodecCtx = ffmpegDecoder->pFormatCtx->streams[ffmpegDecoder->videoStream]->codec;
    
#if  TO_MP4
    ffmpegDecoder->pOutStream = avformat_new_stream(ffmpegDecoder->pOutFormatCtx, NULL);
    {
        AVCodecContext *c = ffmpegDecoder->pOutStream->codec;
        c->bit_rate = ffmpegDecoder->pCodecCtx->bit_rate;
        c->rc_max_rate = ffmpegDecoder->pCodecCtx->rc_max_rate;
        c->codec_id = ffmpegDecoder->pCodecCtx->codec_id;
        c->codec_type = ffmpegDecoder->pCodecCtx->codec_type;
        c->time_base.num = ffmpegDecoder->pCodecCtx->time_base.num;
        c->time_base.den = ffmpegDecoder->pCodecCtx->time_base.den;
        c->gop_size = ffmpegDecoder->pCodecCtx->gop_size;
        c->width = ffmpegDecoder->pCodecCtx->width;
        c->height = ffmpegDecoder->pCodecCtx->height;
        c->pix_fmt = ffmpegDecoder->pCodecCtx->pix_fmt;
        c->flags = ffmpegDecoder->pCodecCtx->flags;
        c->flags |= CODEC_FLAG_GLOBAL_HEADER;
        c->extradata = (uint8_t*)av_malloc(ffmpegDecoder->pCodecCtx->extradata_size);
        c->extradata_size = ffmpegDecoder->pCodecCtx->extradata_size;
        memcpy(c->extradata,ffmpegDecoder->pCodecCtx->extradata,ffmpegDecoder->pCodecCtx->extradata_size);
        c->me_range = ffmpegDecoder->pCodecCtx->me_range;
        c->max_qdiff = ffmpegDecoder->pCodecCtx->max_qdiff;
        c->qmin = ffmpegDecoder->pCodecCtx->qmin;
        c->qmax = ffmpegDecoder->pCodecCtx->qmax;
        c->qcompress = ffmpegDecoder->pCodecCtx->qcompress;
    }
    if(ffmpegDecoder->pOutFormatCtx == NULL)
        goto REALEASE_avformat_find_stream_info;
    
    avio_open(&ffmpegDecoder->pOutFormatCtx->pb, mOutputFileName, AVIO_FLAG_WRITE);
    if(ffmpegDecoder->pOutFormatCtx->pb == NULL){
        goto REALEASE_avformat_find_stream_info;
    }

    avformat_write_header(ffmpegDecoder->pOutFormatCtx, NULL);

    avio_flush(ffmpegDecoder->pOutFormatCtx->pb);
    
#endif
    return ffmpegDecoder;
    /////////////////////////    failed.......  /////////////////////
RELEASE_avcodec_open2:
    avformat_close_input(&ffmpegDecoder->pFormatCtx);
RELEASE_avcodec_find_decoder:
REALEASE_avformat_find_stream_info:
REALEASE_avformat_open_input:
    avformat_free_context(ffmpegDecoder->pFormatCtx);
    ffmpegDecoder->pFormatCtx = NULL;
    av_free(pb);
    
RELEASE_close:
    return NULL;
}

static int ConvertInit(FFMPEG_DECODER **ffmpegDecoder,const char *mInputFileName,const char *mOutputFileName){
  //  int ret ;
    *ffmpegDecoder=myDecodeInit(mInputFileName,mOutputFileName);
    if(!*ffmpegDecoder)
        return -1;
    (*ffmpegDecoder)->firstSaw = 1;
    return 0;
}


static int ConvertExit(FFMPEG_DECODER *ffmpegDecoder){
    int ret;
    if(!ffmpegDecoder)
        return -1;
    
    if(ffmpegDecoder->pOutFormatCtx)
    {
        ret = av_write_trailer(ffmpegDecoder->pOutFormatCtx);

        if(ffmpegDecoder->pCodecCtx)
        {
            avcodec_close(ffmpegDecoder->pCodecCtx);
            ffmpegDecoder->pCodecCtx = NULL;
        }
        if(ffmpegDecoder->pFormatCtx)
        {
            avformat_close_input(&ffmpegDecoder->pFormatCtx);
            avformat_free_context(ffmpegDecoder->pFormatCtx);
            ffmpegDecoder->pFormatCtx = NULL;
        }
        ffmpegDecoder->firstSaw = 0;
    }
    else{
        return -1;
    }
    return 0;
}


static int ConvertH264(FFMPEG_DECODER *ffmpegDecoder){
//    int             frameFinished;
//    struct timeval timeVal;
//    AVPacket        packet;
//    AVPacket        opkt;
//    int ret;
//    static int endTimes = 0;
//    
//    if(!ffmpegDecoder)
//    {
//        return -1;
//    }
//    if(!ffmpegDecoder->pFormatCtx)
//    {
//        return -1;
//    }
//    while( av_read_frame(ffmpegDecoder->pFormatCtx, &packet) >= 0 )
//    {
//        if(packet.size <= 0)
//        {
//            return -1;
//        }
//        if( packet.stream_index == ffmpegDecoder->videoStream ) {
#if  TO_MP4
            //1.set istDts
//            if(ffmpegDecoder->firstSaw){
//                ffmpegDecoder->istDts = ffmpegDecoder->pInStream->avg_frame_rate.num ? - ffmpegDecoder->pInStream->codec->has_b_frames * AV_TIME_BASE / av_q2d(ffmpegDecoder->pInStream->avg_frame_rate) : 0;
//                ffmpegDecoder->istPts = 0;
//                if(packet.pts != AV_NOPTS_VALUE){
//                    ffmpegDecoder->istDts += av_rescale_q(packet.pts,ffmpegDecoder->pInStream->time_base,AV_TIME_BASE_Q);
//                    ffmpegDecoder->istPts = ffmpegDecoder->istDts;
//                }
//                ffmpegDecoder->firstSaw = 0;
//            }
//            if(ffmpegDecoder->istNextDts == AV_NOPTS_VALUE)
//                ffmpegDecoder->istNextDts = ffmpegDecoder->istDts;
//            if(ffmpegDecoder->istNextPts == AV_NOPTS_VALUE)
//                ffmpegDecoder->istNextPts = ffmpegDecoder->istPts;
//            
//            if(packet.dts != AV_NOPTS_VALUE)
//                ffmpegDecoder->istNextDts = ffmpegDecoder->istDts = av_rescale_q(packet.dts,ffmpegDecoder->pInStream->time_base,AV_TIME_BASE_Q);
//            
//            //2.update istNext value
//            ffmpegDecoder->istDts = ffmpegDecoder->istNextDts;
//            if(packet.duration){
//                ffmpegDecoder->istNextDts += av_rescale_q(packet.duration,ffmpegDecoder->pInStream->time_base,AV_TIME_BASE_Q);
//            }else if(ffmpegDecoder->pInStream->codec->time_base.num != 0){
//                int ticks = ffmpegDecoder->pInStream->parser ? ffmpegDecoder->pInStream->parser->repeat_pict + 1 : ffmpegDecoder->pInStream->codec->ticks_per_frame;
//                ffmpegDecoder->istNextDts += ((int64_t)AV_TIME_BASE * ffmpegDecoder->pInStream->codec->time_base.num * ticks) / ffmpegDecoder->pInStream->codec->time_base.den;
//            }
//            ffmpegDecoder->istPts = ffmpegDecoder->istDts;
//            ffmpegDecoder->istNextPts = ffmpegDecoder->istNextDts;
            
            //3.get the out packet
            
//            int64_t ost_tb_start_time = av_rescale_q(0,AV_TIME_BASE_Q,ffmpegDecoder->pOutStream->time_base);
//            
//            av_init_packet(&opkt);
//            
//            if(packet.pts != AV_NOPTS_VALUE)
//                opkt.pts = av_rescale_q(packet.pts,ffmpegDecoder->pInStream->time_base,ffmpegDecoder->pOutStream->time_base) - ost_tb_start_time;
//            else
//                opkt.pts = AV_NOPTS_VALUE;
//            if(packet.dts == AV_NOPTS_VALUE)
//                opkt.dts = av_rescale_q(ffmpegDecoder->istDts,AV_TIME_BASE_Q,ffmpegDecoder->pOutStream->time_base);
//            else
//                opkt.dts = av_rescale_q(packet.dts,ffmpegDecoder->pInStream->time_base,ffmpegDecoder->pOutStream->time_base);
//            opkt.dts -= ost_tb_start_time;
//            
//            if(ffmpegDecoder->pOutStream->codec->codec_id != AV_CODEC_ID_H264
//               && ffmpegDecoder->pOutStream->codec->codec_id != AV_CODEC_ID_MPEG1VIDEO
//               && ffmpegDecoder->pOutStream->codec->codec_id != AV_CODEC_ID_MPEG2VIDEO
//               && ffmpegDecoder->pOutStream->codec->codec_id != AV_CODEC_ID_VC1){
//                if(av_parser_change(ffmpegDecoder->pInStream->parser, ffmpegDecoder->pOutStream->codec,&opkt.data,&opkt.size,packet.data,packet.size, packet.flags & AV_PKT_FLAG_KEY))
//                {
//                    opkt.destruct = av_destruct_packet;
//                }
//            }else{
//                opkt.data = packet.data;
//                opkt.size = packet.size;
//            }
//            av_interleaved_write_frame(ffmpegDecoder->pOutFormatCtx,&opkt);
//            av_free_packet(&opkt);
//            av_free_packet(&packet);
#endif
//        }
//    }
    return 0;
}



@interface P2PInitService()
{
    P2PSDKClient* mSdk;
    NSRecursiveLock *theLock;
}
@end

@implementation P2PInitService

DEFINE_SINGLETON_FOR_CLASS(P2PInitService);


-(NSRecursiveLock *)getTheLock
{
    if (!theLock)
    {
        theLock = [[NSRecursiveLock alloc] init];
    }
    return theLock;
}

-(void)releaseLock
{
    theLock = nil;
}

-(P2PSDKClient*)getP2PSDK
{
    if (!mSdk)
    {
        mSdk = P2PSDKClient::CreateInstance();
        char myId[20] = {0};
        srand((unsigned int)time(NULL));
        long  randomNum = rand();
        sprintf(myId, "ios_%ld", randomNum);
        BOOL bFlag = [self getIPWithHostName:XCLocalized(@"p2pserver")];
        if (bFlag && _strAddress)
        {
            DLog(@"解析出来的ip地址:%@",_strAddress);
            bool ret = mSdk->Initialize([_strAddress UTF8String], myId);
            if (!ret)
            {
                DLog(@"初始化失败");
                [self setP2PSDKNull];
                return NULL;
            }
        }
        else
        {
            DLog(@"解析失败,使用另外一种解析方式");
            bool ret = mSdk->Initialize([XCLocalized(@"p2pserver") UTF8String], myId);
            if (!ret)
            {
                DLog(@"初始化失败");
                [self setP2PSDKNull];
                return NULL;
            }
            else
            {
                
            }

        }
    }
    return mSdk;
}

-(void)setP2PSDKNull
{
    if (mSdk)
    {
        DLog(@"被释放了");
        mSdk->DeInitialize();
        P2PSDKClient::DestroyInstance(mSdk);
    }
    mSdk = NULL;
}

-(BOOL)getIPWithHostName:(const NSString *)hostName
{
    const char *hostN= [hostName UTF8String];
    struct hostent* phot;
    @try
    {
        phot = gethostbyname(hostN);
    }
    @catch (NSException *exception)
    {
        return NO;
    }
    struct in_addr ip_addr;
    if(phot)
    {
        memcpy(&ip_addr, phot->h_addr_list[0], 4);
        char ip[20] = {0};
        inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
        _strAddress = [NSString stringWithUTF8String:ip];
        
        return YES;
    }
    else
    {
        return NO;
    }
}

//-(void)

-(void)convertBlock:(const char *)mInputFileName output:(const char *)mOutputFileName
{
    __weak P2PInitService *__weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__weakSelf h264ToMp4:mInputFileName output:mOutputFileName];
    });
}

-(int)h264ToMp4:(const char *)mInputFileName output:(const char *)mOutputFileName
{

    int ret = 0;
    FFMPEG_DECODER *ffmpegDecoder = NULL;

    usleep(500000);
    if((ret=ConvertInit(&ffmpegDecoder,mInputFileName,mOutputFileName))<0){
        return -1;
    }
    if((ret = ConvertH264(ffmpegDecoder))<0){
        return -1;
    }
    ret = ConvertExit(ffmpegDecoder);
    //修改sql记录
    DLog(@"zhuanhuanchenggong");
    
    if(ffmpegDecoder)
        free(ffmpegDecoder);
    return ret;
}



@end
