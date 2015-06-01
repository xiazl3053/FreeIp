#ifndef __P2PSDKClient_h__
#define __P2PSDKClient_h__

#include "P2PSDK.h"
#include <string>
#include <list>


#ifdef WIN32
#define  DLLCLASS_API __declspec(dllexport)
#else
#define  DLLCLASS_API
#endif

class  NatCommunication;
class  BlockingHook;

class  DLLCLASS_API EventHandler
{
public:
    EventHandler() {};
    virtual ~EventHandler() {};
    virtual bool ProcessFrameData(char* aFrameData, int aFrameDataLength) = 0;  
    virtual bool DeviceDisconnectNotify() =0;	//设备掉线通知
};

class  ConnectionImpl;
// 表示与设备的一个连接,在同一连接上只能打开一路实时流或一路回放流.
class DLLCLASS_API Connection
{
public:
    Connection(EventHandler* handler) ;
   // virtual ~Connection() {};
    ~Connection();

    int  Connect(char* channelId);
    // 关闭连接
    void Close();
    bool IsConnected();
    //int  GetTotalChannel(char *channel);	
    /**
	 * 打开指定通道的实时流
	 * channelId: 设备的通道账号(DVR、NVR通道从0开始)
	 * streamType: 1:主码流  2:辅码流
	 * 返回: 0:success, -1: fail;
	 */
	int StartRealStream(short channelNo, short streamType);
    // 停止实时流
	int StopRealStream(short channelNo, short streamType);

	 /**
	 * 控制设备云台
	 * ptzcmd: 云台控制命令
	 * 返回: 0:success, -1: fail;
	 */
	int PtzContol(PtzControlMsg* ptzmsg);

	 /*远程重启设备*/
	int  Reboot(); 

	/********************************
	 * 获取设备码流和版本相关信息
	 * channelId: 设备的通道账号(DVR、NVR通道从0开始)
	 * streamType: 1:主码流  2:辅码流
	 * 返回: 0:success, -1: fail;
	**************************** */
	int GetDeviceStreamInfo(short channelNo, short streamType); 

        /***********************************
        * 获取设备录像文件相关信息
        recordsearch_req:录像搜索请求信息
        recordsearch_resp:设备录像回复信息
        * 返回: 0:success, -1: fail;
        ***********************************/
	int GetDeviceRecordInfo(struct _playrecordmsg*   recordsearch_req,struct  _playrecordresp*  recordsearch_resp); 
		
    // 打开回放录像
    int PlayBackRecord(PlayRecordMsg* msg);
    // 录像回放控制,包括暂停、快进、快退、停止等。详见PlayBackControl声明.
    int PlayBackRecordCtrl(PlayRecordCtrlMsg* msg);
    
    
private:
    bool connectstatue;
    ConnectionImpl* impl;
    friend class P2PSDKClient;
};

class  RelayConnectionImpl;
class DLLCLASS_API RelayConnection
{
public:
    RelayConnection(EventHandler* handler) ;
     ~RelayConnection();	
    //virtual ~RelayConnection() {};
 
    int  RelayConnect(char* channelId);
    // 关闭连接
    void Close();
    bool IsConnected();	
   // int  GetTotalChannel(char *channel);
    /**
	 * 打开指定通道的实时流
	 * channelId: 设备的通道账号(DVR、NVR通道从0开始)
	 * streamType: 1:主码流  2:辅码流
	 * 返回: 0:success, -1: fail;
	 */
	int StartRealStream(short channelNo, short streamType);
    // 停止实时流
	int StopRealStream(short channelNo, short streamType);

	 /**
	 * 控制设备云台
	 * ptzcmd: 云台控制命令
	 * 返回: 0:success, -1: fail;
	 */
	int PtzContol(PtzControlMsg* ptzmsg);
	 /*远程重启设备*/
	int Reboot();

	/***********************************
        * 获取设备录像文件相关信息
        recordsearch_req:录像搜索请求信息
        recordsearch_resp:设备录像回复信息
        * 返回: 0:success, -1: fail;
        ***********************************/
	int GetDeviceRecordInfo(struct _playrecordmsg*   recordsearch_req,struct  _playrecordresp*  recordsearch_resp); 

       // 打开回放录像
       int PlayBackRecord(PlayRecordMsg* msg);
       // 录像回放控制,包括暂停、快进、快退、停止等。详见PlayBackControl声明.
       int PlayBackRecordCtrl(PlayRecordCtrlMsg* msg);

    /********************************
	 * 获取设备码流和版本相关信息
	 * channelId: 设备的通道账号(DVR、NVR通道从0开始)
	 * streamType: 1:主码流  2:辅码流
	 * 返回: 0:success, -1: fail;
	**************************** */
    int GetDeviceStreamInfo(short channelNo, short streamType); 	
    
    
private:
    bool     connectstatue;	
    RelayConnectionImpl* impl;
    friend class P2PSDKClient;
};

class DLLCLASS_API P2PSDKClient 
{
public:
      static P2PSDKClient* CreateInstance();
      static void DestroyInstance(P2PSDKClient* instance);    
      int SendHeartBeat();	
    // 初始化sdk
	bool Initialize(const char* serverName, const char* myId);    

    // 连接指定的设备, connect必须是类的派生类实例
    int  Connect(char* channelId, Connection* connect);
    int   RelayConnect(char* channelId, RelayConnection* connect);	

    // 释放sdk资源
	void DeInitialize();
private:  
	P2PSDKClient();
	virtual ~P2PSDKClient();    
private: 
	std::string mMyId;
	std::string mServerName;
	NatCommunication* mNatComm;
};

#endif
