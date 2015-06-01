#ifndef SYSTOOL_H
#define SYSTOOL_H

#ifdef __cplusplus
extern "C" {
#endif

/*SYS_WIN_FLAG: 0编译linux版本 1编译window 版本*/
#define SYS_WIN_FLAG 0
/*SYS_DEBUG_FLAG: 0关闭输出 1打开输出*/
#define SYS_DEBUG_FLAG 1

/*获取程序启动到当前微妙数(大约50天会归零)*/
unsigned long SYS_GetTickCount();


#ifdef __cplusplus
}
#endif
#endif
