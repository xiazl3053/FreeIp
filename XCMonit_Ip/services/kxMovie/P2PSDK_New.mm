//
//  P2PSDK_New.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/27.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "P2PSDK_New.h"

BOOL P2PSDK_New::initP2PServer()
{
    if(conn == NULL)
    {
        conn = new Connection(this);
    }
    if (mSdk)
    {
        if(mSdk->Connect((char*)peerName.c_str(), conn)==0)
        {
            DLog(@"P2P连接设备成功");
            return YES;
        }
        DLog(@"P2P连接设备失败");
    }
    delete conn;
    conn = NULL;
    return NO;
}

BOOL P2PSDK_New::initTranServer()
{
    if (mSdk)
    {
        mSdk->SendHeartBeat();
    }
    if(relayconn == NULL)
    {
        relayconn = new RelayConnection(this);
        int ret = mSdk->RelayConnect((char*)peerName.c_str(),relayconn);
        if (ret==0)
        {
            return YES;
        }
    }
    delete relayconn;
    relayconn = NULL;
    return NO;
}

void P2PSDK_New::StopRecv()
{
    DLog(@"结束");
    if (conn)
    {
        if(streamType == 0)
        {
            int ret = conn->StopRealStream(nChannel, streamType);
            if(ret == 0)
            {
                printf("success stop real stream \n");
            }
            else
                printf("error stop real stream \n");
        }
        else if(streamType == 1)
        {
            PlayRecordCtrlMsg msg;
            msg.ctrl = PB_STOP;
            conn->PlayBackRecordCtrl(&msg);
        }
        conn->Close();
        delete conn;
        conn = NULL;
    }
    if(relayconn)
    {
        if(streamType == 0)
        {
            int ret = relayconn->StopRealStream(nChannel, streamType);
            
            if(ret == 0)
            {
                printf("success stop relay stream \n");
            }
        }
        else if(streamType == 1)
        {
            PlayRecordCtrlMsg msg;
            msg.ctrl = PB_STOP;
            relayconn->PlayBackRecordCtrl(&msg);
        }
        relayconn->Close();
        delete relayconn;
        relayconn = NULL;
    }
}

int P2PSDK_New::P2P_GetDeviceRecordInfo(struct _playrecordmsg*   recordsearch_req,struct  _playrecordresp*  recordsearch_resp)
{
    int ret=-1;
//    p2pmutex.lock();
    if(conn != NULL)
    {
        ret = conn->GetDeviceRecordInfo(recordsearch_req,recordsearch_resp);
        if(ret == 0)    //获取录像信息成功
        {
            printf("success P2P_GetDeviceRecordInfo \n");
        }
        else
        {
            printf("P2P_GetDeviceRecordInfo failed \n");
        }
    }
//    p2pmutex.unlock();
    return ret;
}

int P2PSDK_New::RELAY_GetDeviceRecordInfo(struct _playrecordmsg*   recordsearch_req,struct  _playrecordresp*  recordsearch_resp)
{
    int ret=-1;
//    relaymutex.lock();
    if(relayconn != NULL)
    {
        ret = relayconn->GetDeviceRecordInfo(recordsearch_req,recordsearch_resp);
        if(ret == 0)      //获取录像信息成功
        {
            printf("success RELAY_GetDeviceRecordInfo \n");
        }
        else
        {
            printf("RELAY_GetDeviceRecordInfo failed \n");
        }
    }
//    relaymutex.unlock();
    return ret;
}

int P2PSDK_New::TRAN_RecordSerach(struct _playrecordmsg*   recordsearch_req,char*  resp)
{
    printf("RecordSearch \n");
    int  result=-1;
    int i=0;
    struct  _playrecordresp*  recordsearch_resp=NULL;
    struct  _playrecordmsg*    recordmsg=NULL;
    recordsearch_resp = (struct  _playrecordresp*)resp;
    recordmsg = (struct  _playrecordmsg*)(resp+sizeof(recordsearch_resp->count));
    if(relayconn)
    {
        result = RELAY_GetDeviceRecordInfo(recordsearch_req,recordsearch_resp);//中转方式获取录像相关信息
      	if(result<0)
        {
            printf("get recordinfo failed!!!\n");    //获取设备录像信息失败
            return -1;
        }
        else     //获取设备录像信息成功
        {
            if(recordsearch_resp->count == 0)  //录像信息为空(可能无当天录像)
            {
                printf("empty record!!!");
                return -2;
            }
            else
            {
                printf("get recordinfo success!!!record count is %d\n",recordsearch_resp->count);
                for(i=0;i<recordsearch_resp->count;i++)
                {
                    
                    struct tm *p=NULL;
                    char month;
                    char day;
                    char hour;
                    char minute;
                    char Second;
                    p = localtime((const long*)&(recordmsg[i].startTime));
                    month = p->tm_mon + 1;
                    day = p->tm_mday;
                    hour = p->tm_hour;
                    minute = p->tm_min;
                    Second = p->tm_sec;
                    printf( "record[%d] start time is %d-%d %d:%d:%d\n",i,month,day,hour,minute,Second);
                    
                    p = localtime((const long*)&(recordmsg[i].endTime));
                    month = p->tm_mon + 1;
                    day = p->tm_mday;
                    hour = p->tm_hour;
                    minute = p->tm_min;
                    Second = p->tm_sec;
                    printf( "record[%d] end time is %d-%d %d:%d:%d\n",i,month,day,hour,minute,Second);
                }
                return 0;
            }
        }
    }
    return -1;
}

int P2PSDK_New::P2P_RecordSearch(struct _playrecordmsg*   recordsearch_req,char*  resp)
{
    printf("RecordSearch \n");
    int  result=-1;
    int i=0;
    struct  _playrecordresp*  recordsearch_resp=NULL;
    struct  _playrecordmsg*    recordmsg=NULL;
    recordsearch_resp = (struct  _playrecordresp*)resp;
    recordmsg = (struct  _playrecordmsg*)(resp+sizeof(recordsearch_resp->count));
    if(conn)
    {
        result = P2P_GetDeviceRecordInfo(recordsearch_req,recordsearch_resp);//P2P方式获取录像相关信息
        if(result<0)
        {
            printf("get recordinfo failed!!!\n");    //获取设备录像信息失败
            return -1;
        }
        else     //获取设备录像信息成功
        {
            if(recordsearch_resp->count == 0)  //录像信息为空(可能无当天录像)
            {
                printf("empty record!!!");
                return -2;
            }
            else
            {
                printf("get recordinfo success!!!record count is %d\n",recordsearch_resp->count);
                
                for(i=0;i<recordsearch_resp->count;i++)
                {
                    struct tm *p=NULL;
                    char month;
                    char day;
                    char hour;
                    char minute;
                    char Second;
                    p = localtime((const long*)&(recordmsg[i].startTime));
                    month = p->tm_mon + 1;
                    day = p->tm_mday;
                    hour = p->tm_hour;
                    minute = p->tm_min;
                    Second = p->tm_sec;
                    printf( "record[%d] start time is %d-%d %d:%d:%d\n",i,month,day,hour,minute,Second);
                    
                    p = localtime((const long*)&(recordmsg[i].endTime));
                    month = p->tm_mon + 1;
                    day = p->tm_mday;
                    hour = p->tm_hour;
                    minute = p->tm_min;
                    Second = p->tm_sec;
                    printf( "record[%d] end time is %d-%d %d:%d:%d\n",i,month,day,hour,minute,Second);
                }
                return 0;
            }
        }
        
    }
    return -1;
}





bool P2PSDK_New::ProcessFrameData(char* aFrameData, int aFrameDataLength)
{
    return YES;
}
bool P2PSDK_New::DeviceDisconnectNotify()
{
    return YES;
}
