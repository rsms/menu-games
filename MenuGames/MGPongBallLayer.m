//
//  MGPongBallLayer.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGPongBallLayer.h"
#import "MGPongPaddleLayer.h"
#import "MGPongView.h"
#include <math.h>

@implementation MGPongBallLayer

@synthesize gameView = gameView_;

- (id)init {
  self = [super init];
  if (self) {
    // Initialization code here.
    speed_ = 15.0;
    directionX_ = 10.0;
    directionY_ = 10.0;
  }
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (void)update:(NSTimeInterval)period {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  
  // The ball's visual frame
  CGRect frame = self.frame;
  CGRect unmodifiedFrame = frame;
  BOOL recalculate = NO;
  
  // Advance the ball
  CGFloat radians = direction_ * M_PI / 180;
  frame.origin.x += period * speed_ * cosf(radians);
  frame.origin.y += period * speed_ * sinf(radians);
  
  //NSLog(@"radians: %f, period: %f, speed_: %f, cos(r): %f, sin(r): %f",
  //      radians, period, speed_, cosf(radians), sinf(radians));
  
  MGPongPaddleLayer *rightPaddle = gameView_.rightPaddle;
  MGPongPaddleLayer *leftPaddle = gameView_.leftPaddle;
  
  // Check for paddle collisions
  if (CGRectIntersectsRect(frame, rightPaddle.frame)) {
    NSLog(@"HIT right paddle (dir: %f)", direction_);
    
    direction_ = (180+direction_) / 2.0;
    NSLog(@"... (dir2: %f)", direction_);
    recalculate = YES;
  } else if (CGRectIntersectsRect(frame, leftPaddle.frame)) {
    NSLog(@"HIT left paddle");
    direction_ = -direction_ / 2.0;
    recalculate = YES;
  }
  
  // Check for wall collisions
  CGRect gameBounds = rightPaddle.superlayer.bounds;
  if (frame.origin.y < 0.0 || // bottom
      frame.origin.y + frame.size.height > gameBounds.size.height) { // top
    NSLog(@"bounce wall");
    direction_ = -direction_;
    recalculate = YES;
  } else if (frame.origin.x < 0.0) {
    direction_ = (direction_ + 360) / 2;
    NSLog(@"hit left wall -- R player scores");
    recalculate = YES;
  } else if (frame.origin.x + frame.size.width > gameBounds.size.width) {
    direction_ = (direction_ + 360) / 2;
    NSLog(@"hit right wall -- L player scores");
    recalculate = YES;
  }
  
  // Recalculate if we had a collision
  if (recalculate) {
    radians = direction_ * M_PI / 180;
    frame.origin.x = unmodifiedFrame.origin.x + (period * speed_ * cosf(radians));
    frame.origin.y = unmodifiedFrame.origin.y + (period * speed_ * sinf(radians));
  }
  
  //if (!CGRectContainsRect(gameView_.frame, frame)) {
  //  NSLog(@"outside");
  //}
  
  /*if (pos.x > rPaddleFrame.origin.x &&
      pos.x < rPaddleFrame.origin.x + rPaddleFrame.size.width ) {
    if (pos.y >= rPaddleFrame.origin.y &&
        pos.y < rPaddleFrame.origin.y + rPaddleFrame.size.height) {
      NSLog(@"HIT right paddle");
      direction_ = -direction_ / 2.0;
      
      //ball_x_speed *= -1;
      //hits++;
    }
  }*/
  
  self.frame = frame;
  [CATransaction commit];
}


@end
