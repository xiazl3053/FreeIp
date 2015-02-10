//
//  DevInfoMacro.h
//  XCMonit_Ip
//
//  Created by xia zhonglin  on 14-5-19.
//  Copyright (c) 2014年 xia zhonglin . All rights reserved.
//

#ifndef XCMonit_Ip_DevInfoMacro_h
#define XCMonit_Ip_DevInfoMacro_h

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

#define XCFontInfo(x) [UIFont systemFontOfSize:x]
#define kScreenWidth [UIScreen mainScreen].applicationFrame.size.width
#define kScreenHeight [UIScreen mainScreen].applicationFrame.size.height
#define HEIGHT_MENU_VIEW(x,y) ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 ? x : y)
#define PHP_HOST_URL   @"http://www.freeip.com/"
//#define PHP_HOST_URL   @"http://183.57.82.43/ys/"
//http://www.freeip.com/
//http://183.57.82.43/ys/
/*http service*/
//"httpserver" = "http://www.freeip.com/";

/*P2P service*/
//"p2pserver" = "www.freeipc.com";
#endif
