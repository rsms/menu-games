//
//  MGPongView.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGPongBallLayer;

@interface MGPongView : NSView <NSWindowDelegate> {
  CGFloat velocity_;
  CGFloat upVector_;
  CGFloat downVector_;
  CGFloat y_;
  NSSize baseSize_;
  uint64_t timeOfLastUpdate_;
  NSTimer *updateTimer_;
  CALayer *pauseIcon_;
  MGPongBallLayer *ball_;
  CALayer *rightPlayerBar_;
  CALayer *leftPlayerBar_;
}

- (void)toggleFullscreen:(id)sender;
- (BOOL)updateWithTimeInterval:(NSTimeInterval)timeInterval;

@end
