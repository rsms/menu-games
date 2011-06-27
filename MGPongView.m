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
#include <math.h>
#import "MGPongBallLayer.h"
#import "MGPongPaddleLayer.h"
#import "MGPeriodicTimer.h"

// Constants
static const NSSize kPaddleSize = {2.0, 6.0};
static const CGFloat kEdgeToPaddleMargin = 5.0;
static const CGFloat kBallRadius = 2.0;

@interface MGPongView (Private)
- (void)update;
@end


@implementation MGPongView

@synthesize rightPaddle = rightPaddle_, leftPaddle = leftPaddle_;

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (!self) return nil;
  
  [self setWantsLayer:YES];
  
  // Init base size
  baseSize_ = NSMakeSize(0.0, 0.0);
  
  // setup background
  self.layer = [self makeBackingLayer];
  self.layer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.1);
  self.layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
  self.layer.contentsGravity = kCAGravityTopLeft;
  
  // setup left-hand side player bar
  leftPaddle_ = [MGPongPaddleLayer layer];
  leftPaddle_.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
  leftPaddle_.frame = CGRectMake(0.0, 0.0, kPaddleSize.width, kPaddleSize.height);
  leftPaddle_.gameView = self;
  // Note: Don't set delegate here or presentation layer metrics get messed up
  [self.layer addSublayer:leftPaddle_];
  
  // setup right-hand side player bar
  rightPaddle_ = [MGPongPaddleLayer layer];
  rightPaddle_.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
  rightPaddle_.frame = CGRectMake(10.0, 0.0, kPaddleSize.width, kPaddleSize.height);
  rightPaddle_.gameView = self;
  [self.layer addSublayer:rightPaddle_];
  
  // Local player is right-hand side
  localPlayerPaddle_ = rightPaddle_;
  
  // setup ball
  ball_ = [MGPongBallLayer layer];
  ball_.backgroundColor = CGColorCreateGenericRGB(0.8, 0.1, 0.2, 1.0);
  ball_.cornerRadius = 2.0;
  ball_.contentsGravity = kCAGravityCenter;
  ball_.frame = CGRectMake(30.0, 10.0, kBallRadius*2.0, kBallRadius*2.0);
  ball_.gameView = self;
  [self.layer addSublayer:ball_];

  // pause icon up in this bitch
  NSImage *pauseImage = [NSImage imageNamed:@"Pause"];
  pauseIcon_ = [CALayer layer];
  pauseIcon_.contents = pauseImage;
  pauseIcon_.autoresizingMask = kCALayerMinXMargin
                              | kCALayerMaxXMargin
                              | kCALayerMinYMargin
                              | kCALayerMaxYMargin;
  pauseIcon_.contentsGravity = kCAGravityLeft;
  pauseIcon_.bounds = NSMakeRect(0, 0, pauseImage.size.width,
                                 pauseImage.size.height);
  pauseIcon_.opacity = 0;
  [self.layer addSublayer:pauseIcon_];
  
  // Animation timer
  //animationTimer_ = [[MGPeriodicTimer alloc] initWithInterval:1.0/60.0];
  //animationTimer_.delegate = self;
  //[animationTimer_ start];
  [self resumeUpdating];
  
    
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (void)resumeUpdating {
  if (animationTimer_)
    return;
  NSMethodSignature *sig = 
      [isa instanceMethodSignatureForSelector:@selector(update)];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
  [inv setSelector:@selector(update)];
  [inv setTarget:self];
  timeOfLastUpdate_ = mach_absolute_time();
  animationTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0
                                              invocation:inv
                                                 repeats:YES];
  [animationTimer_ retain];
}


- (void)pauseUpdating {
  if (!animationTimer_)
    return;
  [animationTimer_ invalidate];
  [animationTimer_ release];
  animationTimer_ = nil;
}


- (void)update {
  // Calculate period
  uint64_t timeNow = mach_absolute_time();
  mach_timebase_info_data_t info;
  mach_timebase_info(&info);
  NSTimeInterval period = ((double)((timeNow - timeOfLastUpdate_)
                                    * info.numer / info.denom)) / 1000000000.0;
  timeOfLastUpdate_ = timeNow;
  
  // Update ball
  [ball_ update:period];
}


- (void)paddle:(MGPongPaddleLayer*)paddle
destinationChangedFrom:(CGFloat)startYPosition
  withDuration:(CFTimeInterval)duration {
  // TODO: calculate ball trajectory and check for collisions
  NSLog(@"%@ moving from %f -> %f during %f seconds",
        paddle, startYPosition, paddle.position.y, duration);
  
  if (waitingToStartGame_) {
    [self startGame:self];
  }
}


- (void)setFrame:(NSRect)frame {
  if (baseSize_.width == 0.0) {
    // Record initial frame
    baseSize_ = frame.size;

    // Reset game to initial state
    [super setFrame:frame];
    [self resetGame:self];
  } else {
    [super setFrame:frame];
  }
}


- (void)resetGame:(id)sender {
  // Reset things to their initial positions
  NSSize currentSize = self.bounds.size;
  CGFloat paddleCenterY =
      (currentSize.height - rightPaddle_.bounds.size.height) / 2.0;
  
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  
  // Set frame of paddles
  CGRect paddleFrame =
      CGRectMake(currentSize.width - kPaddleSize.width - kEdgeToPaddleMargin,
                 paddleCenterY * 0.5, // over center
                 kPaddleSize.width,
                 kPaddleSize.height);
  rightPaddle_.frame = paddleFrame;
  paddleFrame.origin.x = kEdgeToPaddleMargin;
  paddleFrame.origin.y = paddleCenterY * 1.5; // under center
  leftPaddle_.frame = paddleFrame;
  
  // Set frame of ball
  ball_.frame =
      CGRectMake((currentSize.width / 2.0) - kBallRadius,
                 (currentSize.height / 2.0) - kBallRadius,
                 kBallRadius*2.0, kBallRadius*2.0);
  
  // Now waiting for a player to move in order to start the game
  waitingToStartGame_ = YES;
  
  [CATransaction commit];
}


- (void)startGame:(id)sender {
  // Triggered at first user interaction after the game was reset
  waitingToStartGame_ = NO;
  return;

  
  // Ball animation
  //
  // |---------------------------|
  // |                           |
  // |             • 111111 2 33 |
  // |                           |
  // |---------------------------|
  //
  // Where 1 is the path we know won't collide with anything, 2 is where a
  // collision occur or is avoided, 3 is the path after an avoided collision
  //
  /*CAKeyframeAnimation *ballAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
  CGMutablePathRef thePath = CGPathCreateMutable();
  CGPathMoveToPoint(thePath,NULL,74.0,74.0);
  CGPathAddCurveToPoint(thePath,NULL,74.0,500.0,
                        320.0,500.0,
                        320.0,74.0);
  CGPathAddCurveToPoint(thePath,NULL,320.0,500.0,
                        566.0,500.0,
                        566.0,74.0);
  ballAnim.path = thePath;*/
  
  
  // Start ball animation
  [CATransaction begin];
  
  CGPoint position = ball_.position;
  CGFloat currentX = ((CALayer *)ball_.presentationLayer).position.x;
  //CGFloat leftPaddleX =
  //    leftPaddle_.position.x + leftPaddle_.frame.size.width - kBallRadius;
  CGFloat rightPaddleX = rightPaddle_.position.x - kBallRadius;
  
  CGFloat targetX = rightPaddleX;
  
  // set duration depending on distance
  CGFloat maxX = self.bounds.size.width;
  static const CFTimeInterval baseDuration = 1.2; // seconds it takes to move 100%
  CFTimeInterval duration = (currentX - targetX) / maxX;
  if (duration < 0) duration = -duration;
  duration *= baseDuration;
  [CATransaction setAnimationDuration:duration];
  
  // Use linear movement
  CAMediaTimingFunction *timingFunc =
      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  [CATransaction setAnimationTimingFunction:timingFunc];
  
  // Check collision on completion
  [CATransaction setCompletionBlock:^{
    CGFloat ballY = ball_.position.y;
    CGRect paddleFrame = rightPaddle_.presentationFrame;

    if (ballY >= paddleFrame.origin.y &&
        ballY < paddleFrame.origin.y + paddleFrame.size.height) {
      NSLog(@">> hit");
      //ball_.speed = ball_.speed * -1;
    } else {
      NSLog(@">> miss");
    }
  }];

  position.x = targetX;
  ball_.position = position;
  
  [CATransaction commit];
}


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


- (void)keyDown:(NSEvent *)ev {
  switch (ev.keyCode) {
    case 125: // down
      localPlayerPaddle_.direction = 1;
      //[localPlayerPaddle_ updateWithDirection:1];
      downKeyPressed_ = YES;
      break;
    case 126: // up
      localPlayerPaddle_.direction = -1;
      //[localPlayerPaddle_ updateWithDirection:-1];
      upKeyPressed_ = YES;
      break;
    case 3: // Cmd+F
      if ([NSEvent modifierFlags] & NSCommandKeyMask) {
        [self toggleFullscreen:self];
      }
      break;
    default:
      //NSLog(@"keyDown:%d", ev.keyCode);
      break;
  }
  //NSLog(@"velocity_: %f", velocity_);
}


- (void)keyUp:(NSEvent *)ev {
  
  if ([ev.charactersIgnoringModifiers hasPrefix:@"\033"]) { // esc
    if ([self isInFullScreenMode]) {
      // Exit fullscreen
      [self toggleFullscreen:self];
    }
    return;
  } else if ([ev.charactersIgnoringModifiers hasPrefix:@"r"]) {
    [self resetGame:self];
    return;
  }
  
  switch (ev.keyCode) {
    case 125: // down
      downKeyPressed_ = NO;
      if (localPlayerPaddle_.direction == 1) {
        localPlayerPaddle_.direction = upKeyPressed_ ? -1 : 0;
        //[localPlayerPaddle_ updateWithDirection:upKeyPressed_ ? -1 : 0];
      }
      break;
    case 126: // up
      upKeyPressed_ = NO;
      if (localPlayerPaddle_.direction == -1) {
        localPlayerPaddle_.direction = downKeyPressed_ ? 1 : 0;
        //[localPlayerPaddle_ updateWithDirection:downKeyPressed_ ? 1 : 0];
      }
      break;
    default:
      NSLog(@"keyUp:%d", ev.keyCode);
      break;
  }
}


- (void)drawRect:(NSRect)rect {
}


- (void)toggleFullscreen:(id)sender {
  return; // Note: Currently disabled since it messes up coordinates
  
  CGFloat scaleX = 1.0, scaleY = 1.0;
  
  if ([self isInFullScreenMode]) {
    [self exitFullScreenModeWithOptions:nil];
    [[self window] makeFirstResponder:self];
  } else {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithUnsignedInteger:
                              NSApplicationPresentationHideDock
                              | NSApplicationPresentationAutoHideMenuBar],
                             NSFullScreenModeApplicationPresentationOptions,
                             nil];
    [self enterFullScreenMode:[[self window] screen] withOptions:options];
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

- (void)windowDidBecomeKey:(NSNotification *)notification {
  pauseIcon_.opacity = 0;
}

- (void)windowDidResignKey:(NSNotification *)notification {
  pauseIcon_.opacity = 1;
}

@end
