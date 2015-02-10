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

#define MAX_FRAMESIZE     1024*1024     // 1M


#define ARG_HEAD_LEN 32
#define ARG_BUFF_LEN 1024
#define ARG_SERIALNUM_LEN 8
/*服务器端�?/
#define ARG_SERVER_PORT                   10000
/*收索端口*/
#define ARG_SEARCH_PORT                   10001

/*报文头类�?/
#define ARG_CMD_HEAD                      0x0000
#define ARG_STREAM_HEAD                   0x0001
/*指令类型*/
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


/*SDK版本*/
#define ARG_SDK_VERSION(_major, _minor)( \
    (((_major)&0xff)<<8) | 	\
    (((_minor)&0xff)) \
)
#define ARG_SDK_VERSION_1_1 ARG_SDK_VERSION(1,1)

/*命令状�?错误�?*/
#define CMD_SUCCESS        0x0000    //  成功
#define CMD_VERSION_ERR    0x0001    //  版本错误
#define CMD_NOSUPPORT      0x0002    //  命令不支�?#define CMD_LIMITED        0x0003    //  命令权限不足

#define CMD_ID_ERROR       0x1001    //  用户ID错误
#define CMD_ARGE_ERROR     0x1002    //  参数错误


typedef struct ARG_CMD{
    unsigned short ulFlag;            //  00 00
    unsigned short ulVersion;         //  SDK 版本

    unsigned short usCmd;             //  命令类型
    unsigned short ucState;           //  命令状�?    unsigned long  ulID;              //  用户 ID

    unsigned long  ulBufferSize;      //  扩展内容大小
    unsigned long  ulRes[4];          //  没有使用
}ARG_CMD;
/*码流状�?暂时没有)*/

/*A/V*/
#define AUDIO_FRAME  0
#define VEDIO_FRAME  1

#define ARG_STREAM_MAGIC_NUM          0x00000024

typedef struct ARG_STREAM{
    unsigned short ulFlag;            //  00 01

    unsigned short usState;           //  码流状�?    unsigned long bMediaType:1;       //  A/V
    unsigned long bFrameType:5;       //  帧类�?
    unsigned long bSize:22;           //  帧长�?    unsigned long bSubStream:2;       //  子码�?    unsigned long bRes:2;             //  保留
                                      //  01 - 25/30FPS   // 10 - 50/60FPS  // 11 - 120FPS
    unsigned long  usCH;              //  通道�?0 1 2 3
    unsigned long  ucSerialNum;       //  帧序�?    unsigned long  ulTimeStamp;       //  时间�?
    unsigned short  usWidth;           //  宽度
    unsigned short  usHeight;          //  高度
    unsigned short  ucFrameRate;       //  帧率
    unsigned short  ucBitRate;         //  码率

    unsigned long  ulMagicNum;         //  字节对齐
}ARG_STREAM;


/*设备类型*/
#define ARG_DEV_IPCAMERA  0x00
#define ARG_DEV_DVS       0x01
#define ARG_DEV_NVR       0x02
#define ARG_DEV_DECODER   0x03

typedef struct{
    unsigned char ucDevType;         /*设备类型*/
    unsigned char ucDevName[35];     /*设备名称*/

    unsigned long ulWebPort;         /*网页端口*/
    unsigned long ulRtspPort;        /*rtsp端口*/
    unsigned long ulTcpPort;         /*tcp端口*/

    unsigned long ulIP;              /*IP地址*/
    unsigned long ulNetMash;         /*子网掩码*/
    unsigned long ulGateway;         /*网关*/
    unsigned char ucMacAddress[6];   /*mac地址*/
    unsigned char ucRes[2];          /*保留*/
}SEARCH_INFO;


typedef struct USER_INFO{
    unsigned char ucUsername[16];     // 用户�?    unsigned char ucPassWord[16];     // 密码
    unsigned char ucPower;            // 权限  0管理�? 操作�?2用户
    unsigned char ucRes[3];

    unsigned char ucSerialNum[ARG_SERIALNUM_LEN];
}USER_INFO;

/*码流类型*/
#define STREAMTYPE_MAINSTREAM 0x00
#define STREAMTYPE_SUBSTREAM  0x01

typedef struct STREAM_INFO{
    unsigned char  ucCH;             /*通道�?/
    unsigned char  ucStreamType;     /*码流类型*/
    unsigned char  ucRes[2];         /*保留*/
}STREAM_INFO;

typedef struct PTZ_INFO{
    unsigned char ucCh;
    unsigned char ucDirection;       /*转动方向*/
    unsigned char ucStepSize;        /*步长*/
}PTZ_INFO;

typedef struct TIME_PROPERTY{
    unsigned short usYear;           /*�?/
    unsigned char  ucMonth;          /*�?/
    unsigned char  ucDay;            /*�?/
    unsigned char  ucHour;           /*�?/
    unsigned char  ucMinute;         /*�?/
    unsigned char  ucSecond;         /*�?/
    unsigned char  ucRes[1];         /*保留*/
}TIME_PROPERTY;

typedef struct IMAGE_PROPERTY{
    unsigned char ucCH;              /*通道�?/
    unsigned char ucStreamType;      /*码流类型 0-主码�?1-次码�?/

    unsigned char ucBrightness;      /*亮度*/
    unsigned char ucContrast;        /*对比�?/
    unsigned char ucSaturation;      /*饱和�?/
    unsigned char ucHue;             /*色度*/

    unsigned char ucRes[2];          /*保留*/
}IMAGE_PROPERTY;

typedef struct ENCODING_PROPERTY{
    unsigned char  ucCH;              /*通道�?/
    unsigned char  ucStreamType;      /*码流类型 0-主码�?1-次码�?/

    unsigned char  ucPicQuality;      /*图象质量 0-最�?1-次好 2-较好 3-一�?4-较差 5-�?/
    unsigned char  ucBitrateType;     /*码率类型 0:定码率，1:变码�?/

    unsigned short usWidth;          /*宽度*/
    unsigned short usHeight;         /*高度*/
    unsigned short ucFrameRate;      /*帧率*/
    unsigned short ucBitRate;        /*码率*/

    unsigned char  ucEncodingType;    /*1 h264*/
    unsigned char  ucRes[3];          /*保留*/
}ENCODING_PROPERTY;

typedef struct NET_PROPERTY{
    unsigned char ucNetCardNum;      /*网卡�?/
    unsigned char ucRes[3];          /*保留*/
    unsigned char ulIP[16];              /*IP地址*/
    unsigned char ulSubNetMask[16];      /*子网掩码*/
    unsigned char ulGateway[16];         /*网关*/
    unsigned char ulDNSIP[16];           /*DNS服务器地址*/
}NET_PROPERTY;


#define ALARM TYPE_MOTIONDETECTION 0
typedef struct MOTIONDETECTION_INFO{
    unsigned char ucCH;               /*报警通道*/
    unsigned char ucAlarmType;        /*报警类型 0移动报警 */
    unsigned char ucStatus;           /*报警状�?0开始报�? 1,结束报警*/
    unsigned char ucLevel;            /*报警等级(灵敏�? 0高级 1中级 2低级*/
    unsigned long ulTime;             /*报警时间 1970�?�?�?0:00:00所经过的秒�?/
}MOTIONDETECTION_INFO;

typedef struct MOTIONDETECTION_RECT{
    unsigned char x1;                 /*百分比数  0-100*/
    unsigned char y1;                 /*百分比数  0-100*/
    unsigned char x2;                 /*百分比数  0-100*/
    unsigned char y2;                 /*百分比数  0-100*/
}MOTIONDETECTION_RECT;

typedef struct MOTIONDETECTION_PROPERTY{
    unsigned char ucCH;               /*报警通道*/
    unsigned char ucType;             /*配置方式 0(64切分方式 8*8) 1(鼠标拖动方式)*/
    unsigned char ucRes;              /*保留*/
    unsigned char ucBlock[8];         /*ucBlock[0]的第0位为1 �?4切分的第1行左边第1块区域移动侦测为打开,0为关�?/
    MOTIONDETECTION_RECT ucArea[12];  /*12组百分比区域*/
}MOTIONDETECTION_PROPERTY;




typedef struct private_protocol_info_t
{
    unsigned int run;   //��ʾ�򿪡��ر���Ƶ
    unsigned int ip;
    unsigned int port;

    int cmdSocketFd;    //����socket
    int streamSocketFd;   //ý����socket

    int usercount;    
    int isWaitReply;   //�ȴ�����ظ�
    int isWaitHeartbeatReply;  //�ȴ������ظ�
	
    unsigned long userId;
    unsigned long cmdState;

}private_protocol_info_t;


private_protocol_info_t *private_protocol_init();
void private_protocol_stop(private_protocol_info_t  **pStreamInfo);
int private_protocol_login(private_protocol_info_t *pStreamInfo, unsigned int ip, unsigned int port, char *name, char *passwd);
int private_protocol_getStream(private_protocol_info_t *pStreamInfo, int channelNo, int streamNo);

void RecvOneFramedata(char *data,int datalen);

int StartGetStream(private_protocol_info_t *arg);
void private_protocol_heartbeat(private_protocol_info_t *arg);
void private_protocol_sendHeartbeat(void *arg);
void private_protocol_recvHeartbeat(void *arg);
int SK_ConnectTo(unsigned int ip,int port);
int SK_SelectWait(unsigned int fd, int msec);



#ifdef __cplusplus
}   
#endif      
#endif


