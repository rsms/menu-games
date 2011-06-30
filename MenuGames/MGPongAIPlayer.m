//
//  MGPongAIPlayer.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGPongAIPlayer.h"
#import "MGPongPaddleLayer.h"
#import "MGPongBallLayer.h"


@implementation MGPongAIPlayer

- (id)initWithPaddle:(MGPongPaddleLayer*)paddleLayer {
  if (!(self = [super init])) return nil;
  
  self.paddleLayer = paddleLayer;
  directionY_ = 0.0;
  
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (void)updateWithPeriod:(NSTimeInterval)period
                    ball:(MGPongBallLayer*)ball {
  
  // TODO: support right-hand-side ai
  //if (ball.direction.x > 0.0)
  //  return;
  
  //CGPoint ballDirection = ball.direction;
  CGPoint ballPosition = [ball positionInFuture:period];
  CGRect paddleFrame = self.paddleLayer.frame;
  CGPoint paddlePosition = paddleFrame.origin;
  CGFloat paddleCenterY = paddlePosition.y - (paddleFrame.size.height / 2.0);
  
  // Perfect "AI":
  //paddlePosition.y = ballPosition.y;
  
  // Idea 2
  CGFloat myspeed = 100.0;
  CGFloat distY = ABS(ballPosition.y - paddleCenterY) / 21.0;
  myspeed *= distY;
  NSLog(@"distY: %f", distY);
  
  //Now check if the ball is above or below the paddle and move.
  //But only move if the distance to the ball is bigger than the speed to move!
  if (ballPosition.y > paddleCenterY) {
    paddlePosition.y = MIN(21.0 - paddleFrame.size.height,
                           paddlePosition.y + (myspeed * period));
  } else if (ballPosition.y < paddleCenterY) {
    paddlePosition.y = MAX(0.0, paddlePosition.y - (myspeed * period));
  }
  paddleFrame.origin = paddlePosition;
  NSLog(@"paddleFrame.origin: %@", NSStringFromRect(paddleFrame));
    
  // Set new position
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  self.paddleLayer.frame = paddleFrame;
  [CATransaction commit];
  return;
}


@end
