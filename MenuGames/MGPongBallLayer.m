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


#define CP(__X__,__Y__) CGPointMake(__X__,__Y__)

static CGPoint cp_mul(const CGPoint v, const CGFloat s) {
	return CP(v.x*s, v.y*s);
}
static CGPoint cp_mul2(const CGPoint v1, const CGPoint v2) {
	return CP(v1.x*v2.x, v1.y*v2.y);
}
static CGPoint cp_div(const CGPoint v, const CGFloat s) {
	return CP(v.x/s, v.y/s);
}
static CGPoint cp_add(const CGPoint v1, const CGPoint v2) {
	return CP(v1.x + v2.x, v1.y + v2.y);
}
static CGPoint cp_sub(const CGPoint v1, const CGPoint v2) {
	return CP(v1.x - v2.x, v1.y - v2.y);
}
static CGFloat cp_dot(const CGPoint v1, const CGPoint v2) {
	return v1.x*v2.x + v1.y*v2.y;
}
static CGFloat cp_len(const CGPoint v) {
	return sqrtf(cp_dot(v, v));
}
static CGPoint cp_norm(const CGPoint v) {
	return cp_mul(v, 1.0 / cp_len(v));
}


@implementation MGPongBallLayer

@synthesize gameView = gameView_;

- (id)init {
  self = [super init];
  if (self) {
    // How far the ball moves during 1 second:
    startSpeed_ = 30.0;
    [self reset];
  }
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (void)reset {
  // How far the ball moves during 1 second:
  speed_ = startSpeed_;
  
  // Initial angle
  CGFloat degrees = -35.0;
  CGFloat radians = degrees * M_PI / 180;
  velocity_.x = speed_ * cos(radians);
  velocity_.y = speed_ * sin(radians);
}


- (void)update:(NSTimeInterval)period {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  
  // The ball's visual frame
  CGRect frame = self.frame;
  //CGRect unmodifiedFrame = frame;
  
  // Advance the ball
  frame.origin.x += period * velocity_.x;
  frame.origin.y += period * velocity_.y;
  
  MGPongPaddleLayer *rightPaddle = gameView_.rightPaddle;
  //MGPongPaddleLayer *leftPaddle = gameView_.leftPaddle;
  
  // Check for paddle collisions
  if (CGRectIntersectsRect(frame, rightPaddle.frame)) {
    NSLog(@"hit right paddle");
    
    CGPoint rPaddleCenter =
        CGPointMake((rightPaddle.frame.origin.x -
                     (rightPaddle.frame.size.width / 2.0)),
                    (rightPaddle.frame.origin.y -
                     (rightPaddle.frame.size.height / 2.0)));    
    
    rPaddleCenter.y = frame.origin.y - (rightPaddle.frame.size.width / 2.0);
    
    
    CGFloat cd; // distance between ball centers, aka Collision Distance 
    CGFloat rd; // the sum of the two ball's radii 
    CGFloat ballRadius = frame.size.height / 2.0;
    CGFloat paddleRadius = rightPaddle.frame.size.width / 2.0;
    
    cd = cp_len(cp_sub(frame.origin, rPaddleCenter));
    rd = ballRadius + paddleRadius; 
    
    CGFloat a = (ballRadius * ballRadius - paddleRadius * paddleRadius + rd * rd) / (2 * rd);
    // the point on the line that lays between both circles that is centered in
    // the middle of the collision sector of the overlapping/touching circles 
    // cp = ball1.Location + a * (ball2.Location - ball1.Location) / rd;
    // cp = ((ball1.Location + a) * (ball2.Location - ball1.Location)) / rd;
    CGPoint cp = cp_div(
                        cp_mul2(
                               cp_add(frame.origin, CP(a, a)),
                               cp_sub(rPaddleCenter, frame.origin)
                               ),
                        rd);
    
    
    CGPoint collisionNormal = cp_norm(cp_sub(cp, rPaddleCenter));
    CGFloat dot = cp_dot(collisionNormal, cp_norm(velocity_));
    //CGPoint normalV = cp_norm(velocity_);
    //NSLog(@"normalV: %@ (%f)", NSStringFromPoint(normalV), ((normalV.x + normalV.y)/2.0));
    CGFloat dampening_factor = 1.0;
    velocity_ = cp_mul(
                       cp_norm(
                               cp_mul(
                                      cp_mul(collisionNormal, dot - -1.0),
                                      2.0f
                                      )
                               ),
                       cp_len(velocity_) * dampening_factor);

  }/* else if (CGRectIntersectsRect(frame, leftPaddle.frame)) {
    NSLog(@"hit left paddle");
    //frame.origin.x = leftPaddle.frame.origin.x + leftPaddle.frame.size.width;
    directionX_ = -directionX_;
    recalculate = YES;
  }*/else {
    // Check for wall collisions
    CGRect gameBounds = rightPaddle.superlayer.bounds;
    if (frame.origin.y + frame.size.height > gameBounds.size.height) {
      // top wall
      NSLog(@"bounce top wall");
      frame.origin.y = gameBounds.size.height - frame.size.height;
      velocity_.y = -velocity_.y;
    } else if (frame.origin.x + frame.size.width > gameBounds.size.width) {
      // right wall
      NSLog(@"bounce right wall -- L player scores");
      frame.origin.x = gameBounds.size.width - frame.size.width;
      velocity_.x = -velocity_.x;
    } else if (frame.origin.y < 0.0) {
      // bottom wall
      NSLog(@"bounce bottom wall");
      frame.origin.y = 0.0;
      velocity_.y = -velocity_.y;
    } else if (frame.origin.x < 0.0) {
      // left wall
      NSLog(@"bounce left wall -- R player scores");
      frame.origin.x = 0;
      velocity_.x = -velocity_.x;
    }
  }
  
  self.frame = frame;
  [CATransaction commit];
}


@end
