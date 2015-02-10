/*
 * utils.c
 *
 *  Created on: 2011-9-18
 *      Author: mike
 */

#include "utils.h"

NewQueue* init_queue(int size) {
	NewQueue *queue = NULL; 
	
	printf("queue is  NULL!!!\n");
	queue = (NewQueue*)calloc(1,sizeof(NewQueue));
	if(!queue)
		return NULL;
#ifdef WIN32
	InitializeCriticalSection(&queue->locker);
#else
	pthread_mutex_init(&queue->locker, NULL);
#endif
	queue->buf = (uint8_t*)calloc(1,sizeof(uint8_t)*size);
	if(!queue->buf)
		return NULL;
	queue->read_ptr = queue->write_ptr = 0;
	queue->bufsize = size;
	return queue;
}




void free_queue(NewQueue* que) {
	if(!que)
		return;
#ifdef WIN32
	DeleteCriticalSection(&que->locker);
#else
	pthread_mutex_destroy(&que->locker); 
#endif
	if(que->buf)
		free(que->buf);
	que->buf = NULL;
	free(que);
	que = NULL;
}

void put_queue(NewQueue*que, uint8_t* buf, int size) {
	unsigned char* dst = NULL;
	if(!que || !buf)
		return -1;
	 dst = que->buf + que->write_ptr;
#ifdef WIN32 
	EnterCriticalSection(&que->locker);
#else
	pthread_mutex_lock (&que->locker);
#endif
	if ((que->write_ptr + size) > que->bufsize) {
		memcpy(dst, buf, (que->bufsize - que->write_ptr));
		memcpy(que->buf, buf+(que->bufsize - que->write_ptr), size-(que->bufsize - que->write_ptr));
    } else {
            if(dst != NULL){  
              if((buf+size) != NULL)
		    memcpy(dst, buf, size);
           }
	}
	que->write_ptr = (que->write_ptr + size) % que->bufsize;
#ifdef WIN32 
	LeaveCriticalSection(&que->locker);
#else
	pthread_mutex_unlock (&que->locker);  
#endif
}

int get_queue(NewQueue*que, uint8_t* buf, int size) {
	uint8_t* src = NULL;
	int wrap = 0;
	int pos = 0;
	if(!que || !buf)
	{
		return -1;
	}
	src = que->buf + que->read_ptr;
	
#ifdef WIN32 
	EnterCriticalSection(&que->locker);
#else
	pthread_mutex_lock (&que->locker);
#endif
	if(que->read_ptr > que->write_ptr){
		if( (que->bufsize - (que->read_ptr - que->write_ptr)) < size ){
			pthread_mutex_unlock (&que->locker);
			return -1;
		}
	}else{
		if( (que->write_ptr - que->read_ptr) < size){
			pthread_mutex_unlock (&que->locker);
			return -1;
		}
	}
	pos  = que->write_ptr;
	if (pos < que->read_ptr) {
		pos += que->bufsize;
		wrap = 1;
	}
	if ( (que->read_ptr + size) > pos) {
#ifdef WIN32 
		LeaveCriticalSection(&que->locker);
#else
		pthread_mutex_unlock (&que->locker);  
#endif
		return 1;
	}
	if (wrap) {
		if(size > (que->bufsize-que->read_ptr)){
			memcpy(buf, src, (que->bufsize - que->read_ptr));
			memcpy(buf+(que->bufsize - que->read_ptr), src+(que->bufsize - que->read_ptr), size-(que->bufsize - que->read_ptr));
		}else{
			memcpy(buf, src, sizeof(uint8_t)*size);
		}
	} else {
		memcpy(buf, src, sizeof(uint8_t)*size);
	}
	que->read_ptr = (que->read_ptr + size) % que->bufsize;
#ifdef WIN32 
	LeaveCriticalSection(&que->locker);
#else
	pthread_mutex_unlock (&que->locker);  
#endif

	return 0;
}

