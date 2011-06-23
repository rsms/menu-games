//
//  MGPongView.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGPongView.h"
#include <mach/mach.h>
#include <mach/mach_time.h>

@implementation MGPongView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (!self) return nil;

  velocity_ = 0.0;
  y_ = 0.0;
  upVector_ = downVector_ = 0.0;
  timeOfLastUpdate_ = 0;
  
  // set up main timer
  NSMethodSignature *aSignature = 
      [isa instanceMethodSignatureForSelector:@selector(update)];
  NSInvocation *timerInvocation =
      [NSInvocation invocationWithMethodSignature:aSignature];
  [timerInvocation setSelector:@selector(update)];
  [timerInvocation setTarget:self];
  updateTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0
                                              invocation:timerInvocation
                                                 repeats:YES];
  [updateTimer_ retain];

  return self;
}

- (void)dealloc {
  [super dealloc];
}

// Constants
static const CGFloat friction = 0.1;
static const CGFloat velocityPow = 0.05;
static const NSSize barSize = {2.0, 6.0};
static const CGFloat edgeToBarMargin = 7.0; // include barSize.width

- (void)update {

  /*BOOL firstTime = timeOfLastUpdate_ == 0;
  uint64_t timeNow = mach_absolute_time();
  uint64_t d = timeNow - timeOfLastUpdate_;
  timeOfLastUpdate_ = timeNow;
  if (firstTime) return;
  mach_timebase_info_data_t info;
  mach_timebase_info(&info);
  double time = ((double)(d * info.numer / info.denom)) / 1000000.0;
  // time is milliseconds since last update*/
  
  
  // Edge control
  NSRect bounds = [self bounds];
  y_ = MAX(0.0, MIN(bounds.size.height - barSize.height, y_));
  
  // Modify velocity based on current direction
  velocity_ += downVector_ + upVector_;
  
  // Step y position based on velocity
  y_ += velocity_ * velocityPow;
  
  // Velocity decreases over time
  if (velocity_ > 0.0) {
    velocity_ = MAX(0, velocity_ * (1.0-friction));
  } else if (velocity_ < 0.0) {
    velocity_ = MIN(0, velocity_ * (1.0-friction));
  }
  
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
  NSRect bounds = [self bounds];
  NSSize size = bounds.size;
  
  [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
  [NSBezierPath strokeLineFromPoint:NSMakePoint(0.0, 0.0)
                            toPoint:NSMakePoint(0.0, size.height)];
  [NSBezierPath strokeLineFromPoint:NSMakePoint(size.width, 0.0)
                            toPoint:NSMakePoint(size.width, size.height)];
  
  NSRect padRect = NSMakeRect(size.width - edgeToBarMargin, y_,
                              barSize.width, barSize.height);
  [[NSColor darkGrayColor] set];
  NSRectFill(padRect);
}

- (BOOL)isOpaque {
  return NO;
}

- (BOOL)isFlipped {
  return YES;
}

- (BOOL)canBecomeKeyView {
  return YES;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (BOOL)becomeFirstResponder {
  NSLog(@"becomeFirstResponder");
  return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
  NSLog(@"resignFirstResponder");
  return [super resignFirstResponder];
}

- (void)keyDown:(NSEvent *)ev {
  switch (ev.keyCode) {
    case 125: // down-arrow
      downVector_ = 1.0;
      break;
    case 126: // up-arrow
      upVector_ = -1.0;
      break;
    default:
      NSLog(@"keyDown:%d", ev.keyCode);
      break;
  }
  //NSLog(@"velocity_: %f", velocity_);
}

- (void)keyUp:(NSEvent *)ev {
  switch (ev.keyCode) {
    case 125: // down-arrow
      downVector_ = 0.0;
      break;
    case 126: // up-arrow
      upVector_ = 0.0;
      break;
    default:
      NSLog(@"keyDown:%d", ev.keyCode);
      break;
  }
}

@end
