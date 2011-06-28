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
#import "MGPongPlayer.h"

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
  
  // Player objects
  player1_ = [MGPongPlayer new];
  player2_ = [MGPongPlayer new];
  
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
  player1_.paddleLayer = leftPaddle_;
  
  // setup right-hand side player bar
  rightPaddle_ = [MGPongPaddleLayer layer];
  rightPaddle_.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
  rightPaddle_.frame = CGRectMake(10.0, 0.0, kPaddleSize.width, kPaddleSize.height);
  rightPaddle_.gameView = self;
  [self.layer addSublayer:rightPaddle_];
  player2_.paddleLayer = rightPaddle_;
  
  // Local player
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
  
  // Vertical divider in center
  vDividerLayer_ = [CALayer layer];
  vDividerLayer_.backgroundColor = CGColorCreateGenericGray(0.0, 0.2);
  [self.layer addSublayer:vDividerLayer_];
    
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
  //NSLog(@"%@ moving from %f -> %f during %f seconds",
  //      paddle, startYPosition, paddle.position.y, duration);
  
  if (waitingToStartGame_) {
    [self startGame:self];
  }
}


- (void)ballHitLeftWall:(MGPongBallLayer*)ball {
  if (leftPaddle_ == player1_.paddleLayer) {
    player1_.score = player1_.score - 0.2;
  } else {
    player2_.score = player2_.score - 0.2;
  }
  [self resetGame:self];
  waitingToStartGame_ = NO;
  [self performSelector:@selector(resetGame:) withObject:self afterDelay:0.5];
}

- (void)ballHitRightWall:(MGPongBallLayer*)ball {
  if (rightPaddle_ == player1_.paddleLayer) {
    player1_.score = player1_.score - 0.2;
  } else {
    player2_.score = player2_.score - 0.2;
  }
  [self resetGame:self];
  waitingToStartGame_ = NO;
  [self performSelector:@selector(resetGame:) withObject:self afterDelay:0.5];
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
  
  // Update vertical divider frame
  vDividerLayer_.frame = CGRectMake(ceil(frame.size.width / 2.0), 0.0,
                                    1.0, frame.size.height);
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
  [ball_ reset];
  
  // Now waiting for a player to move in order to start the game
  waitingToStartGame_ = YES;
  [self pauseUpdating];
  
  [CATransaction commit];
}


- (void)startGame:(id)sender {
  // Triggered at first user interaction after the game was reset
  waitingToStartGame_ = NO;
  [self resumeUpdating];
}


- (MGPongPaddleLayer*)firstPlayerPaddle {
  return localPlayerPaddle_;
}


- (MGPongPaddleLayer*)secondPlayerPaddle {
  return (localPlayerPaddle_ == leftPaddle_) ? rightPaddle_ : leftPaddle_;
}


- (void)keyDown:(NSEvent *)ev {
  unichar ch = [ev.charactersIgnoringModifiers characterAtIndex:0];
  switch (ch) {
    case NSUpArrowFunctionKey:
      self.firstPlayerPaddle.direction = -1;
      up1KeyPressed_ = YES;
      return;
    case NSDownArrowFunctionKey:
      self.firstPlayerPaddle.direction = 1;
      down1KeyPressed_ = YES;
      return;
    case 'w': // up for other player
      up2KeyPressed_ = YES;
      if (!remotePlayerPaddle_) {
        self.secondPlayerPaddle.direction = -1;
        return;
      }
      break;
    case 's': // down for other player
      down2KeyPressed_ = YES;
      if (!remotePlayerPaddle_) {
        self.secondPlayerPaddle.direction = 1;
        return;
      }
      break;
    default:
      //NSLog(@"keyDown:%d", ch);
      break;
  }
  [super keyDown:ev];
}


- (void)keyUp:(NSEvent *)ev {
  MGPongPaddleLayer *paddle = nil;
  unichar ch = [ev.charactersIgnoringModifiers characterAtIndex:0];
  switch (ch) {
    case NSUpArrowFunctionKey:
      up1KeyPressed_ = NO;
      paddle = self.firstPlayerPaddle;
      if (paddle.direction == -1) {
        paddle.direction = down1KeyPressed_ ? 1 : 0;
      }
      return;
    case NSDownArrowFunctionKey:
      down1KeyPressed_ = NO;
      paddle = self.firstPlayerPaddle;
      if (paddle.direction == 1) {
        paddle.direction = up1KeyPressed_ ? -1 : 0;
      }
      return;
    case 'w': // up for 2nd player
      up2KeyPressed_ = NO;
      if (!remotePlayerPaddle_) {
        paddle = self.secondPlayerPaddle;
        if (paddle.direction == -1) {
          paddle.direction = down2KeyPressed_ ? 1 : 0;
        }
      }
      return;
    case 's': // down for 2nd player
      down2KeyPressed_ = NO;
      if (!remotePlayerPaddle_) {
        paddle = self.secondPlayerPaddle;
        if (paddle.direction == 1) {
          paddle.direction = up2KeyPressed_ ? -1 : 0;
        }
      }
      return;
    case '\033': // ESC
      if ([self isInFullScreenMode]) {
        // Exit fullscreen
        [self toggleFullscreen:self];
        return;
      }
      break;
    case 'f': // Cmd+F = toggle fullscreen
      if ([NSEvent modifierFlags] & NSCommandKeyMask) {
        [self toggleFullscreen:self];
        return;
      }
      break;
    case 'r': // Cmd+F = reset game
      if ([NSEvent modifierFlags] & NSCommandKeyMask) {
        [self resetGame:self];
        return;
      }
      break;
    default:
      //NSLog(@"keyUp: %d", ch);
      break;
  }
  [super keyUp:ev];
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
  [CATransaction setDisableActions:YES];
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
  waitingToStartGame_ = YES; // resume updating at first user interaction
  pauseIcon_.opacity = 0;
}

- (void)windowDidResignKey:(NSNotification *)notification {
  [self pauseUpdating];
  pauseIcon_.opacity = 1;
}

@end
