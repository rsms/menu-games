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
    self.contentsGravity = kCAGravityCenter;
    self.backgroundColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    self.cornerRadius = 20.0;
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (void)display {
  // check the value of the layer's state key
  //if (self.state) {
    // meh...
  //}
}


/*- (void)drawInContext:(CGContextRef)theContext {
  CGMutablePathRef thePath = CGPathCreateMutable();
  
  CGPathMoveToPoint(thePath, NULL, 15.0, 15.0);
  CGPathAddCurveToPoint(thePath,
                        NULL,
                        15.f,250.0f,
                        295.0f,250.0f,
                        295.0f,15.0f);
  
  CGContextBeginPath(theContext);
  CGContextAddPath(theContext, thePath );
  
  CGContextSetLineWidth(theContext, 2.0);
  CGContextSetStrokeColorWithColor(theContext,
                                   self.lineColor);
  CGContextStrokePath(theContext);
  CFRelease(thePath);
}*/

@end
