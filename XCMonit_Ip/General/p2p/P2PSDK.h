
#ifdef __cplusplus
extern "C" {
#endif

#ifndef __P2PSDK_H__
#define __P2PSDK_H__



//#include <string>
#include <stdio.h>
#define MAX_MSG_DATA_LEN 2048
#define  MAX_VERSION_LENGTH   32

#ifdef _MSC_VER_
#pragma pack(push, 1)
#define PP_PACKED
#elif defined(__GNUC__)
#define PP_PACKED __attribute__ ((packed))
#else
#define PP_PACKED
#endif

typedef struct 
{    
    short           resultCode;  //     返回结果代码
    
}PP_PACKED NetMsgResHeader;

// 实时视频帧和录像回放视频帧前的帧头
typedef struct 
{
    unsigned int  timeStamp ; // 时间戳，从回放的开始时间经过的毫秒数
    unsigned int  videoLen;   // 视频帧长度 (不包括帧头)
    unsigned char bIframe;    // 是否是关键帧。0： 非关键帧 1:关键帧
    unsigned char reserved[7]; // 保留
}PP_PACKED P2P_FrameHeader;

//***************************** 实时流相关消息 ********************************
// 打开实时流消息
typedef struct PlayRealStreamMsg
{
    short streamType;  // 1:主码流 2:副码流
    short channelNo;  // 通道号
}PlayRealStreamMsg;

// 停止实时流消息
typedef struct StopRealStreamMsg
{
    short streamType;  // 1:主码流 2:副码流
    short channelNo;  // 通道号
}StopRealStreamMsg;

// 实时流请求应答
typedef struct 
{
    NetMsgResHeader header;
    // 可能需要扩展其它属性
}PP_PACKED PlayRealStreamMsgRes;

// 关闭实时流请求应答
typedef struct 
{
    NetMsgResHeader header;
    // 可能需要扩展其它属性
}PP_PACKED StopRealStreamMsgRes;


//***************************** 录像回放相关消息 ****************************
#if 0
// 录像回放消息
typedef struct _playrecordmsg
{
	unsigned short        channelNo;                 // 通道号
	unsigned short        frameType;		// 帧类型(0:视频,1:音频,2:音视频) 
	unsigned int            startTime;	                // 开始时间
	unsigned int            endTime;		        // 结束时间
	unsigned int            nalarmFileType;        // 1:普通录像文件   2:报警录像文件 
}PP_PACKED PlayRecordMsg;

typedef struct  _NvrRecordinfo
{
	unsigned short diskNo;//硬盘号
	unsigned short recordNo;// 录像文件（%04X，则为录像文件名）
	unsigned short fileType;//文件类型  bit0：定时录像 bit1：告警录像 bit2：手动录像
	unsigned char unused[2];//
	unsigned int startTime;//录像起始时间（秒）
	unsigned int endTime;//录像结束时间（秒）
	unsigned int startAddr;//该文件第一帧对应的录像文件中I帧索引的地址
	unsigned int endAddr;//该文件最后一帧对应的录像文件中I帧索引的地址
	unsigned int dataStartAddr;//录像文件起始地址
	unsigned int dataEndAddr;//录像数据文件结束地址
}PP_PACKED RecordFileMsg;
typedef struct  _NvrRecordfile
{
	unsigned int  count;  //录像文件总个数
	struct  _NvrRecordinfo*  RecordInfo;
}PP_PACKED RecordFileMsg;
typedef enum {
	DVR		      		      = 0,	//DVR设备
	NVR			              = 1,	//NVR设备
}DeviceType;
typedef struct  _playrecordresp
{
	DeviceType    devicetype;  //设备类型(区分设备类型的原因是因为NVR和DVR的录像 文件信息结构体不一样，而且不好统一)
	char              recordmsg[MAX_MSG_DATA_LEN];//录像文件信息(DVR录像文件信息和NVR录像文件信息结构体不一样)
}PP_PACKED PlayRecordResMsg;
#endif
// 录像回放应答消息
typedef struct _playrecordmsg
{
	unsigned short        channelNo;                 // 通道号
	unsigned short        frameType;		// 帧类型(0:视频,1:音频,2:音视频) 
	unsigned int            startTime;	                // 开始时间
	unsigned int            endTime;		        // 结束时间
	unsigned int            nalarmFileType;        // 1:普通录像文件   2:报警录像文件
	char                       reserve[8];                //保留
}PP_PACKED PlayRecordMsg;
typedef struct  _playrecordresp
{
	unsigned int  count;  //录像文件总个数
	struct  _playrecordmsg*  RecordInfo;
}PP_PACKED PlayRecordResMsg;

typedef enum {
	PB_PLAY		        		= 0,	//播放
	PB_PAUSE			    	= 1,	//暂停
	PB_STEPFORWARD		      = 2,	//单帧进
	PB_STEPBACKWARD		      = 3,	//单帧退
	PB_FORWARD			      = 4,	//快进
	PB_BACKWARD			      = 5,	//快退
}PlayBackControl;

// 录像回放控制消息
typedef struct 
{
    unsigned short        channelNo;                 // 通道号
    unsigned short        frameType;		// 帧类型(0:视频,1:音频,2:音视频) 	
    PlayBackControl ctrl;
}PP_PACKED PlayRecordCtrlMsg;

// 录像回放控制应答消息
typedef struct 
{
    NetMsgResHeader header;
}PP_PACKED PlayRecordCtrlResMsg;
typedef enum {
	PTZCONTROLTYPE_INVALID		= 0,
	PTZCONTROLTYPE_UP_START 	= 1,    //开始向上转动
	PTZCONTROLTYPE_UP_STOP		= 2,
	PTZCONTROLTYPE_DOWN_START		= 3,
	PTZCONTROLTYPE_DOWN_STOP		= 4,
	PTZCONTROLTYPE_LEFT_START		= 5, 
	PTZCONTROLTYPE_LEFT_STOP		= 6,
	PTZCONTROLTYPE_RIGHT_START		= 7,
	PTZCONTROLTYPE_RIGHT_STOP		= 8,
	PTZCONTROLTYPE_UPLEFT_START 	= 9,     //开始向左上转动
	PTZCONTROLTYPE_UPLEFT_STOP		= 10,  
	PTZCONTROLTYPE_UPRIGHT_START		= 11,
	PTZCONTROLTYPE_UPRIGHT_STOP 	= 12,
	PTZCONTROLTYPE_DOWNLEFT_START		= 13,
	PTZCONTROLTYPE_DOWNLEFT_STOP		= 14,
	PTZCONTROLTYPE_DOWNRIGHT_START	= 15,
	PTZCONTROLTYPE_DOWNRIGHT_STOP	= 16,
	PTZCONTROLTYPE_ZOOMWIDE_START		= 17,    //放大
	PTZCONTROLTYPE_ZOOMWIDE_STOP		= 18,
	PTZCONTROLTYPE_ZOOMTELE_START		= 19,   //缩小
	PTZCONTROLTYPE_ZOOMTELE_STOP		= 20,
	PTZCONTROLTYPE_FOCUSNEAR_START	= 21,           //聚焦拉近
	PTZCONTROLTYPE_FOCUSNEAR_STOP	= 22,
	PTZCONTROLTYPE_FOCUSFAR_START	= 23,           //聚焦拉远
	PTZCONTROLTYPE_FOCUSFAR_STOP	= 24,
} PTZCONTROLTYPE;
typedef struct  _PtzControlMsg
{
	PTZCONTROLTYPE   ptzcmd;
	int                           channel;  // 对应通道号(从0开始) 
}PP_PACKED PtzControlMsg;
typedef struct _DeviceStreamMsg
{
    short streamType;  // 1:主码流 2:副码流
    short channelNo;  // 通道号
}DeviceStreamMsgReq;
//************************************************************************
typedef struct 
{
    int       streamsend_statue;     //码流的发送状态    0:failed    1:成功
    int       framerate;  //帧率
    int       streambitrate;   //码流大小
    char     deviceversion[MAX_VERSION_LENGTH];  //设备版本信息
}PP_PACKED DeviceStreamInfoResp;

// 消息类型
typedef enum
{
    UNKOWN_MSG =0, 
    PLAY_REAL_STREAM = 1 ,
    PLAY_REAL_STREAM_RES =2 ,
    STOP_REAL_STREAM = 3 ,
    STOP_REAL_STREAM_RES =4  ,
    PLAY_RECORD_STREAM = 5,   // 请求回放录像流消息类型
    PLAY_RECORD_STREAM_RES = 6,
    PLAY_RECORD_CTRL = 7 ,    // 录像回放控制命令，包括暂停、快进快退等。
    PLAY_RECORD_CTRL_RES = 8,
    RELAY_STREAM_DATA = 9,
    START_PTZ_CTRL = 10,
    START_PTZ_CTRL_RES = 11,
    SYSTEM_REBOOT = 12,
    GET_DEVICE_STREAMINFO = 13,
    GET_DEVICE_STREAMINFO_RES = 14,
    GET_DEVICE_RECORDINFO = 15,
    GET_DEVICE_RECORDINFO_RES = 16,
    STOP_RECORD_STREAM = 17,   // 停止回放录像流消息类型
    STOP_RECORD_STREAM_RES = 18,
}MsgType;
// 请求消息
typedef struct _NetMsg
{
	unsigned short  msgType;
    unsigned short  msgDataLen;
	unsigned char   msgData[MAX_MSG_DATA_LEN]; 
	/*_NetMsg()
	{
		msgType = 0;
        msgDataLen = 0;
		for(int i = 0;i < MAX_MSG_DATA_LEN;i++)
		{
			msgData[i] = '\0';
		}
	}*/
}PP_PACKED NetMsg;

// 消息应答
typedef struct _NetMsgRes
{
    unsigned short  msgType; // 消息类型
    unsigned short  msgDataLen;                  // 应用层消息体长度
	unsigned char   msgData[MAX_MSG_DATA_LEN];   //  应用层消息体数据
}PP_PACKED NetMsgRes;

#ifdef _MSC_VER_
#pragma pack(pop)
#endif

#endif
#ifdef __cplusplus
}
#endif
