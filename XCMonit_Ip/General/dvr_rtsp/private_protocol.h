#ifndef PRIVATE_PROTOCOL
#define PRIVATE_PROTOCOL

#ifdef __cplusplus
extern "C"
{
#endif

#define PP_FREE(P) if(0!=P){free(P); P=0;}
#define PP_CLOSE_FD(fd) if(-1!=fd){ close(fd); fd = -1;}
#define MAX_PRIVATE_PROTOCOL_CHANNEL_NUM 32
#define MAX_PRIVATE_PROTOCOL_STREAM_NUM  2

#define MAX_FRAMESIZE     1024*1024


#define ARG_HEAD_LEN 32
#define ARG_BUFF_LEN 1024
#define ARG_SERIALNUM_LEN 8

#define ARG_SERVER_PORT                   10000

#define ARG_SEARCH_PORT                   10001


#define ARG_CMD_HEAD                      0x0000
#define ARG_STREAM_HEAD                   0x0001

#define CMD_ACT_LOGIN                     0x0000
#define CMD_ACT_LOGOUT                    0x0001
#define CMD_ACT_CREATE_USER               0x0002
#define CMD_ACT_DELETE_USER               0x0003
#define CMD_ACT_MODIFY_USER               0x0004
#define CMD_ACT_PTZ                       0x0005
#define CMD_ACT_HEADRTBEAT                0x0006
#define CMD_ATC_SEARCH                	  0x0007
#define CMD_ATC_SEARCH_RESPONSE           0x0008

#define CMD_GET_SERIALNUM                 0x0101
#define CMD_GET_STREAM                    0x0102

#define CMD_GET_TIME_PRORERTY             0x1000
#define CMD_SET_TIME_PRORERTY             0x1001
#define CMD_GET_ENCODING_PROPERTY         0x1002
#define CMD_SET_ENCODING_PROPERTY         0x1003
#define CMD_GET_IMAGE_PROPERTY            0x1004
#define CMD_SET_IMAGE_PROPERTY            0x1005
#define CMD_GET_NET_PROPERTY              0x1006
#define CMD_SET_NET_PROPERTY              0x1007
#define CMD_GET_MOTIONDETECTION_PROPERTY  0x1008
#define CMD_SET_MOTIONDETECTION_PROPERTY  0x1009



#define ARG_SDK_VERSION(_major, _minor)( \
    (((_major)&0xff)<<8) | 	\
    (((_minor)&0xff)) \
)
#define ARG_SDK_VERSION_1_1 ARG_SDK_VERSION(1,1)


#define CMD_SUCCESS        0x0000
#define CMD_VERSION_ERR    0x0001
#define CMD_NOSUPPORT      0x0002
#define CMD_LIMITED        0x0003

#define CMD_ID_ERROR       0x1001
#define CMD_ARGE_ERROR     0x1002


typedef struct ARG_CMD{
    unsigned short ulFlag;
    unsigned short ulVersion;

    unsigned short usCmd;
    unsigned short ucState;
    unsigned int  ulID;

    unsigned int  ulBufferSize;
    unsigned int  ulRes[4];
}ARG_CMD;


/*A/V*/
#define AUDIO_FRAME  0
#define VEDIO_FRAME  1

#define ARG_STREAM_MAGIC_NUM          0x00000024

typedef struct ARG_STREAM{
    unsigned short ulFlag;
    
    unsigned short usState;
    
    unsigned int bMediaType:1;
    unsigned int bFrameType:5;
    unsigned int bSize:22;
    unsigned int bSubStream:2;
    
    unsigned int bRes:2;
    
    unsigned int  usCH;
    unsigned int  ucSerialNum;
    unsigned int  ulTimeStamp;
    
    unsigned short  usWidth;
    unsigned short  usHeight;
    unsigned short  ucFrameRate;
    unsigned short  ucBitRate;
    
    unsigned int  ulMagicNum;
}ARG_STREAM;


/*设备类型*/
#define ARG_DEV_IPCAMERA  0x00
#define ARG_DEV_DVS       0x01
#define ARG_DEV_NVR       0x02
#define ARG_DEV_DECODER   0x03

typedef struct
{
    unsigned char ucDevType;
    unsigned char ucDevName[35];

    unsigned long ulWebPort;
    unsigned long ulRtspPort;
    unsigned long ulTcpPort;

    unsigned long ulIP;
    unsigned long ulNetMash;
    unsigned long ulGateway;
    unsigned char ucMacAddress[6];
    unsigned char ucRes[2];
}SEARCH_INFO;


typedef struct USER_INFO{
    unsigned char ucUsername[16];
    unsigned char ucPassWord[16];
    unsigned char ucPower;
    unsigned char ucRes[3];

    unsigned char ucSerialNum[ARG_SERIALNUM_LEN];
}USER_INFO;

/*码流类型*/
#define STREAMTYPE_MAINSTREAM 0x00
#define STREAMTYPE_SUBSTREAM  0x01

typedef struct STREAM_INFO{
    unsigned char  ucCH;
    unsigned char  ucStreamType;
    unsigned char  ucRes[2];
}STREAM_INFO;

typedef struct PTZ_INFO{
    unsigned char ucCh;
    unsigned char ucDirection;
    unsigned char ucStepSize;
}PTZ_INFO;

typedef struct TIME_PROPERTY{
    unsigned short usYear;
    unsigned char  ucMonth;
    unsigned char  ucDay;
    unsigned char  ucHour;
    unsigned char  ucMinute;
    unsigned char  ucSecond;
    unsigned char  ucRes[1];
}TIME_PROPERTY;

typedef struct IMAGE_PROPERTY{
    unsigned char ucCH;
    unsigned char ucStreamType;

    unsigned char ucBrightness;
    unsigned char ucContrast;
    unsigned char ucSaturation;
    unsigned char ucHue;

    unsigned char ucRes[2];
}IMAGE_PROPERTY;

typedef struct ENCODING_PROPERTY{
    unsigned char  ucCH;
    unsigned char  ucStreamType;

    unsigned char  ucPicQuality;
    unsigned char  ucBitrateType;

    unsigned short usWidth;
    unsigned short usHeight;
    unsigned short ucFrameRate;
    unsigned short ucBitRate;

    unsigned char  ucEncodingType;
    unsigned char  ucRes[3];
}ENCODING_PROPERTY;

typedef struct NET_PROPERTY{
    unsigned char ucNetCardNum;
    unsigned char ucRes[3];
    unsigned char ulIP[16];
    unsigned char ulSubNetMask[16];
    unsigned char ulGateway[16];
    unsigned char ulDNSIP[16];
}NET_PROPERTY;


#define ALARM TYPE_MOTIONDETECTION 0
typedef struct MOTIONDETECTION_INFO{
    unsigned char ucCH;
    unsigned char ucAlarmType;
    unsigned char ucStatus;
    unsigned char ucLevel;
    unsigned long ulTime;
}MOTIONDETECTION_INFO;

typedef struct MOTIONDETECTION_RECT{
    unsigned char x1;
    unsigned char y1;
    unsigned char x2;
    unsigned char y2;
}MOTIONDETECTION_RECT;

typedef struct MOTIONDETECTION_PROPERTY{
    unsigned char ucCH;
    unsigned char ucType;
    unsigned char ucRes;
    unsigned char ucBlock[8];
    MOTIONDETECTION_RECT ucArea[12];
}MOTIONDETECTION_PROPERTY;


typedef int (*GET_NEXT_FRAME_DATA)(void *opaque, unsigned char* buf, int buf_size);

typedef struct private_protocol_info_t
{
    unsigned int run;
    unsigned int ip;
    unsigned int port;

    int cmdSocketFd;
    int streamSocketFd;

    int usercount;    
    int isWaitReply;
    int isWaitHeartbeatReply;
	
    unsigned long userId;
    unsigned long cmdState;
    
 //

}private_protocol_info_t;

private_protocol_info_t *private_protocol_init();
void* private_protocol_stop(private_protocol_info_t  **pStreamInfo);
int private_protocol_login(private_protocol_info_t *pStreamInfo, unsigned int ip, unsigned int port, char *name, char *passwd);
int private_protocol_getStream(private_protocol_info_t *pStreamInfo, int channelNo, int streamNo);
void setFrameData(GET_NEXT_FRAME_DATA frame);
void RecvOneFramedata(char *data,int datalen);

int StartGetStream(private_protocol_info_t *arg);
void* private_protocol_heartbeat(private_protocol_info_t *arg);
void* private_protocol_sendHeartbeat(void *arg);
void* private_protocol_recvHeartbeat(void *arg);
int SK_ConnectTo(unsigned int ip,int port);
int SK_SelectWait(unsigned int fd, int msec);
    int private_protocol_logout(private_protocol_info_t *pStreamInfo);

void setUserData(void* user);
    

#ifdef __cplusplus

}
#endif      
#endif


