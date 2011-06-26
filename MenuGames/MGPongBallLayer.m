//
//  MGPongBallLayer.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGPongBallLayer.h"


@implementation MGPongBallLayer

- (id)init {
  self = [super init];
  if (self) {
    // Initialization code here.
  }
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (CGFloat)targetYPosition {
  return self.position.y;
}


- (void)setTargetYPosition:(CGFloat)y {
  CGPoint position = self.position;
  position.y = y;
  self.position = position;
}


@end
