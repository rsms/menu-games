//
//  MGPongPaddleLayer.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGPongPaddleLayer.h"
#import "MGPongView.h"


@implementation MGPongPaddleLayer

@synthesize gameView = gameView_;


- (id)init {
  self = [super init];
  if (self) {
    // Initialization code here.
    direction_ = 0;
  }
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (int)direction {
  return direction_;
}


- (CGRect)presentationFrame {
  return ((CALayer *)self.presentationLayer).frame;
}


- (void)setDirection:(int)direction {
  if (direction_ == direction)
    return; // noop
  
  NSSize currentSize = self.superlayer.bounds.size;
  CGFloat minY = self.bounds.size.height / 2.0;
  CGFloat maxY = currentSize.height - minY;
  
  CALayer *presentationLayer = (CALayer *)self.presentationLayer;
  CGPoint position = presentationLayer.position;
  CGFloat currentY = position.y;
  //NSLog(@"currentY: %f", currentY);
  //NSLog(@"currentY 2: %f", ((CALayer*)self.presentationLayer).frame.origin.y);
  
  [CATransaction begin];
  
  if (direction == 0) {
    // Halt!
    CGFloat distanceTravelled = (previousY_ - position.y) / maxY;
    if (distanceTravelled < 0) distanceTravelled = -distanceTravelled;
    //NSLog(@"halt (distanceTravelled: %f)", distanceTravelled);
    static const CGFloat mass = 0.3;
    if (direction_ < 0) {
      position.y = MIN(maxY, position.y * (1.0 + (distanceTravelled * mass)));
    } else {
      position.y = MAX(minY, position.y * (1.0 - (distanceTravelled * mass)));
    }
  } else {
    // Set destination
    if (direction > 0) { // down
      //NSLog(@"down");
      position.y = minY;
    } else { // up
      //NSLog(@"up");
      position.y = maxY;
    }
  }
  
  // set duration depending on distance
  static const CFTimeInterval baseDuration = 2.0; // seconds it takes to move 100%
  CFTimeInterval duration = (currentY - position.y) / maxY;
  if (duration < 0) duration = -duration;
  duration *= baseDuration;
  //duration = 1.0;
  [CATransaction setAnimationDuration:duration];
  
  //NSLog(@"position.y = %f\n-----", position.y);
  
  self.position = position;
  
  [CATransaction commit];
  
  if (gameView_) {
    [gameView_ paddle:self destinationChangedFrom:currentY
         withDuration:duration];
  }
  
  direction_ = direction;
  previousY_ = currentY;
}


@end
