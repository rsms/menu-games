//
//  MGPeriodicTimer.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGPeriodicTimerDelegate.h"

@interface MGPeriodicTimer : NSObject {
  id<MGPeriodicTimerDelegate> delegate_;
  NSTimeInterval interval_;
  pthread_t thread_;
  BOOL isRunning_;
  volatile BOOL stopTimerFlag_;
}

@property (retain) id<MGPeriodicTimerDelegate> delegate;

- (id)initWithInterval:(NSTimeInterval)interval;
- (void)start;
- (void)stop;

@end

