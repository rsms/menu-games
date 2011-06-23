//
//  MGPongView.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGPongView : NSView <NSWindowDelegate> {
  CGFloat velocity_;
  CGFloat upVector_;
  CGFloat downVector_;
  CGFloat y_;
  uint64_t timeOfLastUpdate_;
  NSTimer *updateTimer_;
  CALayer *pauseIcon_;
}

@end
