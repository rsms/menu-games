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
    speed_ = startSpeed_ = 30.0;
    
    // Initial angle
    /*CGFloat degrees = -35.0;
    CGFloat radians = degrees * M_PI / 180;
    directionX_ = speed_ * cos(radians);
    directionY_ = speed_ * sin(radians);*/
    
    velocity_ = CP(20.0, 20.0);
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
  frame.origin.x += period * velocity_.x;
  frame.origin.y += period * velocity_.y;
  
  //NSLog(@"radians: %f, period: %f, speed_: %f, cos(r): %f, sin(r): %f",
  //      radians, period, speed_, cosf(radians), sinf(radians));
  
  MGPongPaddleLayer *rightPaddle = gameView_.rightPaddle;
  //MGPongPaddleLayer *leftPaddle = gameView_.leftPaddle;
  
  // Check for right paddle collision
  /*CGRect paddleFrame = rightPaddle.frame;
  if (frame.origin.y + frame.size.height > paddleFrame.size.height) {
    // top wall
    NSLog(@"r: bounce top");
    frame.origin.y = paddleFrame.size.height - frame.size.height;
    directionY_ = -directionY_;
  } else if (frame.origin.x + frame.size.width > paddleFrame.size.width) {
    // right wall
    NSLog(@"r: bounce right");
    frame.origin.x = paddleFrame.size.width - frame.size.width;
    directionX_ = -directionX_;
  } else if (frame.origin.y < 0.0) {
    // bottom wall
    NSLog(@"r: bounce bottom");
    frame.origin.y = 0.0;
    directionY_ = -directionY_;
  } else if (frame.origin.x < 0.0) {
    // left wall
    NSLog(@"r: bounce left");
    frame.origin.x = 0;
    directionX_ = -directionX_;
  }*/
  
  // Check for paddle collisions
  if (CGRectIntersectsRect(frame, rightPaddle.frame)) {
    NSLog(@"hit right paddle");
    
    CGPoint rPaddleCenter =
        CGPointMake((rightPaddle.frame.origin.x -
                     (rightPaddle.frame.size.width / 2.0)),
                    (frame.origin.y -
                     (rightPaddle.frame.size.width / 2.0)));    
    
    // get the mtd (minimum translation distance)

    CGPoint delta = CP(frame.origin.x - rPaddleCenter.x,
                       frame.origin.y - rPaddleCenter.y);
    
    CGFloat d = sqrt(delta.x*delta.x + delta.y*delta.y);
    
    // minimum translation distance to push balls apart after intersecting
    CGFloat ballRadius = frame.size.height / 2.0;
    CGFloat paddleRadius = rightPaddle.frame.size.width / 2.0;
    CGPoint mtd = cp_mul(delta, ((ballRadius + paddleRadius)-d)/d);
    
    // resolve intersection --
    // inverse mass quantities
    CGFloat ballMass = 4.0;
    CGFloat paddleMass = 8.0;
    CGFloat im1 = 1.0 / ballMass;
    CGFloat im2 = 1.0 / paddleMass;
    
    // push-pull them apart based off their mass
    frame.origin = cp_add(frame.origin, cp_mul(mtd, (im1 / (im1 + im2))));
    //frame.origin = cp_sub(frame.origin, cp_mul(mtd, (im2 / (im1 + im2))));
    
    // impact speed
    CGPoint v = velocity_;//cp_sub(velocity_, CP(0.0, 0.0));
    CGFloat vn = cp_dot(v, cp_norm(mtd));
    
    // sphere intersecting but moving away from each other already
    if (vn > 0.0f) {
      NSLog(@"CASE 1");
    } else {
      // collision impulse
      #define RESTITUTION_CONSTANT 0.0
      CGFloat i = (-(RESTITUTION_CONSTANT) * vn) / (ballMass + paddleMass);
      CGPoint impulse = cp_mul(mtd, i);

      // change in momentum
      velocity_ = cp_add(velocity_, cp_mul(impulse, im1));
      //velocity_ = cp_sub(velocity_, cp_mul(impulse, im2));
      //ball.velocity = ccpSub(ball.velocity, cp_mul(impulse, im2));
    }
    
    //recalculate = YES;

    
    
    /*CGFloat distX = rPaddleCenter.x - unmodifiedFrame.origin.x;
    CGFloat distY = rPaddleCenter.y - unmodifiedFrame.origin.y;
    CGFloat radians = tan(distY / distX);
    CGFloat c = cos(radians);
    CGFloat s = sin(radians);
    NSLog(@"angle: %f (%f, %f)", radians * 180 / M_PI, c, s);
    
    //frame.origin.x = rightPaddle.frame.origin.x - frame.size.width;
    directionX_ = speed_ * c;
    directionY_ = speed_ * s;
    //recalculate = YES;
    frame = unmodifiedFrame;
    speed_ = MIN(speed_ * 1.2, startSpeed_ * 3.0);*/
  }/* else if (CGRectIntersectsRect(frame, leftPaddle.frame)) {
    NSLog(@"hit left paddle");
    //frame.origin.x = leftPaddle.frame.origin.x + leftPaddle.frame.size.width;
    directionX_ = -directionX_;
    recalculate = YES;
  }*/
  
  if (recalculate) {
    frame.origin.x = unmodifiedFrame.origin.x + (period * velocity_.x);
    frame.origin.y = unmodifiedFrame.origin.y + (period * velocity_.y);
  }
  
  // Check for wall collisions
  CGRect gameBounds = rightPaddle.superlayer.bounds;
  if (frame.origin.y + frame.size.height > gameBounds.size.height) {
    // top wall
    NSLog(@"bounce top wall");
    frame.origin.y = gameBounds.size.height - frame.size.height;
    velocity_.y = -velocity_.y;
  } else if (frame.origin.x + frame.size.width > gameBounds.size.width) {
    // right wall
    NSLog(@"bounce right wall");
    frame.origin.x = gameBounds.size.width - frame.size.width;
    velocity_.x = -velocity_.x;
  } else if (frame.origin.y < 0.0) {
    // bottom wall
    NSLog(@"bounce bottom wall");
    frame.origin.y = 0.0;
    velocity_.y = -velocity_.y;
  } else if (frame.origin.x < 0.0) {
    // left wall
    NSLog(@"bounce left wall");
    frame.origin.x = 0;
    velocity_.x = -velocity_.x;
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
