//
//  MGPeriodicTimer.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGPeriodicTimer.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <pthread.h>


@interface MGPeriodicTimer (Private)
- (void)main;
@end


static void *threadFunc(void *param) {
  MGPeriodicTimer *timer = (MGPeriodicTimer*)param;
  [timer main];
  return NULL;
}


@implementation MGPeriodicTimer

@synthesize delegate = delegate_;


- (id)initWithInterval:(NSTimeInterval)interval {
  if (!(self = [super init])) return nil;
  interval_ = interval;
  return self;
}

- (id)init {
  [self release];
  return nil;
}


- (void)dealloc {
  [super dealloc];
}


- (void)start {
  if (isRunning_) return;
  stopTimerFlag_ = NO;
  isRunning_ = YES;
  
  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_setscope(&attr, PTHREAD_SCOPE_SYSTEM);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
  /*
   if( setPriority ){
   sched_param param;
   int resultCode = pthread_attr_getschedparam( &attr, &param );
   assert( resultCode == 0 );
   
   param.sched_priority = priority;
   
   resultCode =pthread_attr_setschedparam ( &attr, &param );
   assert( resultCode == 0 );
   }
   */
  int resultCode = pthread_create(&thread_, &attr, threadFunc, self);
  pthread_attr_destroy(&attr);
  
  assert(resultCode == 0);
}


- (void)main {
  //fprintf(stderr,"Getting real-time priority\n");
  struct thread_time_constraint_policy ttcpolicy;
  ttcpolicy.period = 833333;
  ttcpolicy.computation = 60000;
  ttcpolicy.constraint = 120000;
  ttcpolicy.preemptible = 1;
  
  if (thread_policy_set(mach_thread_self(),
                        THREAD_TIME_CONSTRAINT_POLICY, (int *)&ttcpolicy,
                        THREAD_TIME_CONSTRAINT_POLICY_COUNT) != KERN_SUCCESS) {
    NSLog(@"WARN: thread_policy_set failed");
  }
  
  mach_timebase_info_data_t tbi;
  mach_timebase_info(&tbi);
  double invRatio = ((double)tbi.denom) / ((double)tbi.numer);
  double timeResNanos = interval_ * 1000000000.0; // In nanosecond
  double nextDateNanos, curDateNanos = mach_absolute_time() / invRatio;
  
  while (!stopTimerFlag_) {
    pthread_testcancel();
    nextDateNanos = mach_absolute_time() / invRatio;
    while (curDateNanos < nextDateNanos) {
      [delegate_ periodicTimerTick];
      curDateNanos += timeResNanos;
    }
    mach_wait_until(curDateNanos * invRatio);
  }
}


- (void)stop {
}

@end
