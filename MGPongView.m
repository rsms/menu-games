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
#import "MGPongBallLayer.h"


@implementation MGPongView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (!self) return nil;
  
  [self setWantsLayer:YES];

  // initial values TODO: move into appropriate class
  velocity_ = 0.0;
  y_ = 0.0;
  upVector_ = downVector_ = 0.0;
  timeOfLastUpdate_ = 0;
  
  // Init base size
  baseSize_ = NSMakeSize(0.0, 0.0);
  
  // setup background
  self.layer = [self makeBackingLayer];
  self.layer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.1);
  self.layer.contentsGravity = kCAGravityTopLeft;
  
  // setup right-hand side player bar
  rightPlayerBar_ = [CALayer layer];
  rightPlayerBar_.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
  rightPlayerBar_.frame = CGRectMake(10.0, 0.0, 2.0, 6.0);
  [self.layer addSublayer:rightPlayerBar_];
  
  // setup left-hand side player bar
  leftPlayerBar_ = [CALayer layer];
  leftPlayerBar_.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
  leftPlayerBar_.frame = CGRectMake(0.0, 0.0, 2.0, 6.0);
  [self.layer addSublayer:leftPlayerBar_];
  
  // setup ball
  ball_ = [MGPongBallLayer layer];
  ball_.backgroundColor = CGColorCreateGenericRGB(0.8, 0.1, 0.2, 1.0);
  ball_.cornerRadius = 2.0;
  ball_.contentsGravity = kCAGravityCenter;
  ball_.frame = CGRectMake(30.0, 10.0, 4.0, 4.0);
  [self.layer addSublayer:ball_];
  
  // set up main timer
  /*NSMethodSignature *aSignature = 
      [isa instanceMethodSignatureForSelector:@selector(update)];
  NSInvocation *timerInvocation =
      [NSInvocation invocationWithMethodSignature:aSignature];
  [timerInvocation setSelector:@selector(update)];
  [timerInvocation setTarget:self];
  updateTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0
                                              invocation:timerInvocation
                                                 repeats:YES];
  [updateTimer_ retain];*/

  return self;
}

- (void)dealloc {
  [super dealloc];
}


- (void)setFrame:(NSRect)frame {
  if (baseSize_.width == 0.0) {
    // Record base size
    baseSize_ = frame.size;
  }
  [super setFrame:frame];
}


// Constants
static const CGFloat friction = 0.1;
static const CGFloat velocityPow = 0.05;
static const NSSize barSize = {2.0, 6.0};
static const CGFloat edgeToBarMargin = 7.0; // include barSize.width

- (BOOL)updateWithTimeInterval:(NSTimeInterval)timeInterval {
  /*x += timeInterval * speed * cos(trajectory);
  y += timeInterval * speed * sin(trajectory);
  
  if (x > GAME_ASPECT + (0.5 + GAME_OBJECT_BOUNDARY_EXCESS) * width) {
    x = -0.5 * width;
  } else if (x < -(0.5 + GAME_OBJECT_BOUNDARY_EXCESS) * width) {
    x = GAME_ASPECT + 0.5 * width;
  }
  
  if (y > 1.0 + (0.5 + GAME_OBJECT_BOUNDARY_EXCESS) * height) {
    y = -0.5 * height;
  } else if (y < -(0.5 + GAME_OBJECT_BOUNDARY_EXCESS) * height) {
    y = 1.0 + 0.5 * height;
  }
  */
  return NO;
}

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
}


- (void)toggleFullscreen:(id)sender {
  CGFloat scaleX = 1.0, scaleY = 1.0;
  
  if ([self isInFullScreenMode]) {
    [self exitFullScreenModeWithOptions:nil];
    [[self window] makeFirstResponder:self];
  } else {
    [self enterFullScreenMode:[[self window] screen] withOptions:nil];
    for (NSView *view in [NSArray arrayWithArray:[self subviews]]) {
      [view removeFromSuperview];
      [self addSubview:view];
    }
    NSSize currentSize = [self bounds].size;
    scaleX = currentSize.width / baseSize_.width;
    scaleY = scaleX;
    //scaleY = currentSize.height / baseSize_.height;
  }
  
  // Scale
  [CATransaction begin];
  [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
  self.layer.transform = CATransform3DMakeScale(scaleX, scaleY, 1.0);
  [CATransaction commit];
  [self setNeedsDisplay:YES];
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
    case 3: // Cmd+F
      if ([NSEvent modifierFlags] & NSCommandKeyMask) {
        [self toggleFullscreen:self];
      }
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
      
      // xxx test
      //rightPlayerBar_.frame = CGRectMake(0.0, 21.0, 2.0, 6.0);
      CGPoint pos = rightPlayerBar_.position;
      pos.y = 21.0;
      rightPlayerBar_.position = pos;
      
      break;
    case 126: // up-arrow
      upVector_ = 0.0;
      break;
    case 53: // ESC
      if ([self isInFullScreenMode]) {
        // Exit fullscreen
        [self toggleFullscreen:self];
      }
      break;
    default:
      NSLog(@"keyUp:%d", ev.keyCode);
      break;
  }
}

@end
