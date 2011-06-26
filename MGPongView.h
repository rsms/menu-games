//
//  MGPongView.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class MGPongBallLayer, MGPongPaddleLayer;

@interface MGPongView : NSView <NSWindowDelegate> {
  NSSize baseSize_;
  CALayer *pauseIcon_;
  MGPongBallLayer *ball_;
  MGPongPaddleLayer *rightPaddle_;
  MGPongPaddleLayer *leftPaddle_;
  __weak MGPongPaddleLayer *localPlayerPaddle_;
  BOOL upKeyPressed_;
  BOOL downKeyPressed_;
  BOOL waitingToStartGame_;
}

- (void)toggleFullscreen:(id)sender;
- (void)resetGame:(id)sender;
- (void)startGame:(id)sender;

- (void)paddle:(MGPongPaddleLayer*)paddle
destinationChangedFrom:(CGFloat)startYPosition
  withDuration:(CFTimeInterval)duration;

@end
