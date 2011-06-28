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
static CGFloat deg2rad(const CGFloat degrees) {
  return (M_PI / 180) * degrees;
}
static CGFloat rad2deg(const CGFloat radians) {
  return radians * 180 / M_PI;
}


@implementation MGPongBallLayer

@synthesize gameView = gameView_;

- (id)init {
  self = [super init];
  if (self) {
    [self reset];
  }
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (void)reset {
  // How far the ball moves during 1 second:
  const CGFloat speed = 30.0;
  
  // Initial angle
  const CGFloat radians = 0.0;
  velocity_.x = speed * cos(radians);
  velocity_.y = speed * sin(radians);
}


/*- (BOOL)collideWithPaddle:(MGPongPaddleLayer*)paddle
                ballFrame:(CGRect)ballFrame
                dampening:(CGFloat)dampening {
  // Check for paddle collisions
  if (!CGRectIntersectsRect(ballFrame, paddle.frame))
    return NO;

  CGPoint ballCenter =
      CP((ballFrame.origin.x - (ballFrame.size.width / 2.0)),
         (ballFrame.origin.y - (ballFrame.size.height / 2.0)) );
  CGPoint paddleCenter =
      CP((paddle.frame.origin.x - (paddle.frame.size.width / 2.0)),
         ballFrame.origin.y - (paddle.frame.size.width / 2.0));
  CGFloat ballRadius = ballFrame.size.height / 2.0;
  CGFloat paddleRadius = paddle.frame.size.width / 2.0;
  
  // get the mtd
  CGPoint delta = dampening > 0.0 ? cp_add(ballCenter, paddleCenter)
                                  : cp_sub(ballCenter, paddleCenter);
  CGFloat d = cp_len(delta);
  // minimum translation distance to push balls apart after intersecting
  CGPoint mtd = cp_mul(delta, ((ballRadius + paddleRadius)-d)/d); 
  
  
  // resolve intersection --
  // inverse mass quantities
  //CGFloat im1 = 1.0; //1.0 / ballMass;
  //CGFloat im2 = 1.0; //1.0 / paddleMass;
  
  // push-pull them apart based off their mass
  CGPoint newBallCenter = cp_sub(ballCenter, mtd);
  self.position = newBallCenter;
  
  // impact speed
  CGFloat vn = cp_dot(velocity_, cp_norm(mtd));
  
  // sphere intersecting but moving away from each other already
  if (vn > 0.0) return YES;
  
  // collision impulse
  static const CGFloat kRestitution = 0.8f;
  CGFloat i = (-(1.0f + kRestitution) * vn); // (im1 + im2);
  CGPoint impulse = cp_mul(mtd, i);
  
  // change in momentum
  velocity_ = cp_add(velocity_, impulse);
  //ball.velocity = ball.velocity.subtract(impulse.multiply(im2));
  
  return YES;
}*/


- (BOOL)collideWithPaddle:(MGPongPaddleLayer*)paddle
                ballFrame:(CGRect)ballFrame
             isLeftPaddle:(BOOL)isLeftPaddle {
  // Check for paddle collisions
  CGRect paddleFrame = paddle.presentationFrame;
  if (CGRectIntersectsRect(ballFrame, paddleFrame)) {
    CGPoint paddleCenter =
        CP((paddleFrame.origin.x - (paddleFrame.size.width / 2.0)),
           paddleFrame.origin.y - (paddleFrame.size.width / 2.0));
    CGPoint ballCenter =
        CP((ballFrame.origin.x - (ballFrame.size.width / 2.0)),
           (ballFrame.origin.y - (ballFrame.size.height / 2.0)) );
    
    CGFloat cd; // distance between ball centers, aka Collision Distance 
    CGFloat rd; // the sum of the two ball's radii 
    CGFloat ballRadius = ballFrame.size.height / 2.0;
    CGFloat paddleRadius = paddleFrame.size.width / 2.0;
    
    cd = cp_len(cp_sub(ballCenter, paddleCenter));
    rd = ballRadius + paddleRadius; 
    
    CGFloat a =
        (ballRadius * ballRadius - paddleRadius * paddleRadius + rd * rd)
        / (2 * rd);
    // the point on the line that lays between both circles that is centered in
    // the middle of the collision sector of the overlapping/touching circles 
    // cp = ball1.Location + a * (ball2.Location - ball1.Location) / rd;
    // cp = ((ball1.Location + a) * (ball2.Location - ball1.Location)) / rd;
    CGPoint cp = cp_div(
                        cp_mul2(
                                cp_add(ballCenter, CP(a, a)),
                                cp_sub(paddleCenter, ballCenter)
                                ),
                        rd);
    
    
    CGPoint collisionNormal = cp_norm(cp_sub(cp, paddleCenter));
    CGFloat dot = cp_dot(collisionNormal, cp_norm(velocity_));
    
    // TODO: test on radians and limit angle based on "if v1 < r...
    //CGFloat radians = acos(dot);
    //if (isLeftPaddle && radians < ) {...
    
    #if 0  // DEBUG: draw collision normals extending from paddle center
    CGFloat radians = acos(dot);
    CALayer *lineLayer = [CALayer layer];
    lineLayer.backgroundColor = CGColorCreateGenericGray(0.0, 0.6);
    lineLayer.position = paddleCenter;
    lineLayer.bounds = (CGRect) { {0, 0}, {100.0, 1.0} };
    lineLayer.transform = CATransform3DMakeRotation(radians, 0, 0, 1);
    [paddle.superlayer addSublayer:lineLayer];
    //NSLog(@"collisionNormal: %@ (%f)", NSStringFromPoint(collisionNormal),
    //      rad2deg(radians));
    #endif
    
    velocity_ = cp_mul(
                       cp_norm(
                               cp_mul(
                                      cp_mul(collisionNormal, dot - -1.0),
                                      2.0f
                                      )
                               ),
                       cp_len(velocity_) * -1.0);
    
    return YES;
  }
  return NO;
}


- (void)update:(NSTimeInterval)period {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  
  // The ball's visual frame
  CGRect frame = self.frame;
  
  // Advance the ball
  frame.origin.x += period * velocity_.x;
  frame.origin.y += period * velocity_.y;
  
  MGPongPaddleLayer *rightPaddle = gameView_.rightPaddle;
  MGPongPaddleLayer *leftPaddle = gameView_.leftPaddle;
  
  // Check for paddle collisions
  if ([self collideWithPaddle:rightPaddle ballFrame:frame isLeftPaddle:NO]) {
    // ok, hit right paddle. Trigger some event or something in the future
    NSLog(@"hit right paddle");
    frame.origin.x += period * velocity_.x;
    frame.origin.y += period * velocity_.y;
  } else if ([self collideWithPaddle:leftPaddle ballFrame:frame isLeftPaddle:YES]) {
    // ok, hit left paddle. Trigger some event or something in the future
    NSLog(@"hit left paddle");
    frame.origin.x += period * velocity_.x;
    frame.origin.y += period * velocity_.y;
  } else {
    // Check for wall collisions
    CGRect gameBounds = rightPaddle.superlayer.bounds;
    if (frame.origin.y + frame.size.height > gameBounds.size.height) {
      // top wall
      frame.origin.y = gameBounds.size.height - frame.size.height;
      velocity_.y = -velocity_.y;
    } else if (frame.origin.x + frame.size.width > gameBounds.size.width) {
      // right wall
      frame.origin.x = gameBounds.size.width - frame.size.width;
      velocity_.x = -velocity_.x;
      [gameView_ ballHitRightWall:self];
    } else if (frame.origin.y < 0.0) {
      // bottom wall
      frame.origin.y = 0.0;
      velocity_.y = -velocity_.y;
    } else if (frame.origin.x < 0.0) {
      // left wall
      frame.origin.x = 0;
      velocity_.x = -velocity_.x;
      [gameView_ ballHitLeftWall:self];
    }
  }
  
  self.frame = frame;
  [CATransaction commit];
}


@end
