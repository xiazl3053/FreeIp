#ifndef __UTILS_H_
#define __UTILS_H_

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>
#include <stdint.h>
#ifdef WIN32 
#include <windows.h>
#else
#include <pthread.h>
#endif




typedef struct NewQueue{
#ifdef WIN32 
	CRITICAL_SECTION locker;
#else
	pthread_mutex_t locker;
#endif
	uint8_t* buf;
	int bufsize;
	int write_ptr;
	int read_ptr;
} NewQueue;


extern NewQueue* init_queue(int size);
//extern int init_queue(NewQueue *que, int size);
extern void free_queue(NewQueue* que);
extern void put_queue(NewQueue* que, uint8_t* buf, int size);
extern int get_queue(NewQueue* que, uint8_t* buf, int size);

#endif /*end of __UTILS_H*/
