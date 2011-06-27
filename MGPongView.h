//
//  MGPongView.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "MGPeriodicTimerDelegate.h"

@class MGPongBallLayer, MGPongPaddleLayer, MGPeriodicTimer;

@interface MGPongView : NSView <NSWindowDelegate> {
  NSSize baseSize_;
  CALayer *pauseIcon_;
  NSTimer *animationTimer_;
  MGPongBallLayer *ball_;
  MGPongPaddleLayer *rightPaddle_;
  MGPongPaddleLayer *leftPaddle_;
  __weak MGPongPaddleLayer *localPlayerPaddle_;
  BOOL upKeyPressed_;
  BOOL downKeyPressed_;
  BOOL waitingToStartGame_;
  uint64_t timeOfLastUpdate_;
}

@property (readonly) MGPongPaddleLayer *rightPaddle;
@property (readonly) MGPongPaddleLayer *leftPaddle;

- (void)toggleFullscreen:(id)sender;
- (void)resetGame:(id)sender;
- (void)startGame:(id)sender;

- (void)resumeUpdating;
- (void)pauseUpdating;

- (void)paddle:(MGPongPaddleLayer*)paddle
destinationChangedFrom:(CGFloat)startYPosition
  withDuration:(CFTimeInterval)duration;

@end
