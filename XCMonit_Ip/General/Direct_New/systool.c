#include "systool.h"

#if SYS_WIN_FLAG

#else
#include <sys/time.h>
#endif



#if     SYS_DEBUG_FLAG
#define SYS_DEBUG(fmt,args...) printf("DEBUG %s-%d: "fmt"\n",__FUNCTION__,__LINE__,## args);
#else
#define SYS_DEBUG(fmt,args...)
#endif


unsigned long SYS_GetTickCount()
{
    static unsigned long  s_msec = 0;
    unsigned long         msec = 0;

#if SYS_WIN_FLAG


#else
    struct timeval        time;
    struct timezone       zone;
    gettimeofday (&time , &zone);
    msec =  (time.tv_sec * 1000);
    msec += (time.tv_usec / 1000);
#endif
    if(0==s_msec){s_msec = msec;}
    msec -=s_msec;

    return msec;
}
