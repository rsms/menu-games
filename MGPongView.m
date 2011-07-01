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
#import "MGPongAIPlayer.h"

// Constants
static const NSSize kPaddleSize = {2.0, 6.0};
static const CGFloat kEdgeToPaddleMargin = 5.0;
static const CGFloat kBallRadius = 2.0;

@interface MGPongView (Private)
- (void)update;
@end


@implementation MGPongView

@synthesize rightPaddle = rightPaddle_,
            leftPaddle = leftPaddle_,
            isWarmingUp = isWarmingUp_;

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (!self) return nil;
  
  [self setWantsLayer:YES];
  
  // Init base size
  baseSize_ = NSMakeSize(0.0, 0.0);
  
  // setup background
  self.layer = [self makeBackingLayer];
  //self.layer.backgroundColor = CGColorCreateGenericGray(0.0, 0.05);
  self.layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
  self.layer.contentsGravity = kCAGravityTopLeft;
  
  // Vertical divider in center
  vDividerLayer_ = [CALayer layer];
  vDividerLayer_.backgroundColor = CGColorCreateGenericGray(0.0, 0.15);
  [self.layer addSublayer:vDividerLayer_];
  
  // Left and right border dividers
  leftDividerLayer_ = [CALayer layer];
  rightDividerLayer_ = [CALayer layer];
  leftDividerLayer_.backgroundColor = CGColorCreateGenericGray(0.0, 0.3);
  rightDividerLayer_.backgroundColor = leftDividerLayer_.backgroundColor;
  [self.layer addSublayer:leftDividerLayer_];
  [self.layer addSublayer:rightDividerLayer_];
  
  // setup left-hand side player bar
  leftPaddle_ = [MGPongPaddleLayer layer];
  leftPaddle_.backgroundColor = CGColorCreateGenericRGB(0.0, 0.45, 0.74, 1.0);
  leftPaddle_.frame = CGRectMake(0.0, 0.0, kPaddleSize.width, kPaddleSize.height);
  leftPaddle_.gameView = self;
  // Note: Don't set delegate here or presentation layer metrics get messed up
  [self.layer addSublayer:leftPaddle_];
  
  // setup right-hand side player bar
  rightPaddle_ = [MGPongPaddleLayer layer];
  rightPaddle_.backgroundColor = CGColorCreateGenericRGB(0.62, 0.16, 0.0, 1.0);
  rightPaddle_.frame = CGRectMake(10.0, 0.0, kPaddleSize.width, kPaddleSize.height);
  rightPaddle_.gameView = self;
  [self.layer addSublayer:rightPaddle_];
  
  // Local player
  localPlayerPaddle_ = rightPaddle_;
  
  // setup ball
  ball_ = [MGPongBallLayer layer];
  ball_.backgroundColor = CGColorCreateGenericGray(0.0, 1.0);
  ball_.cornerRadius = kBallRadius;
  ball_.contentsGravity = kCAGravityCenter;
  ball_.frame = CGRectMake(30.0, 10.0, kBallRadius*2.0, kBallRadius*2.0);
  ball_.gameView = self;
  [self.layer addSublayer:ball_];
  
  // Banner ("winner", "you")
  NSImage *image = [NSImage imageNamed:@"you-banner-right"];
  banner_ = [CALayer layer];
  banner_.contents = image;
  banner_.autoresizingMask = kCALayerMinXMargin
                           | kCALayerMaxXMargin
                           | kCALayerMinYMargin
                           | kCALayerMaxYMargin;
  banner_.contentsGravity = kCAGravityLeft;
  banner_.bounds = NSMakeRect(0.0, 0.0, 50.0, 21.0); // match banner pixels
  banner_.opacity = 0.0;
  [self.layer addSublayer:banner_];
  
  // pause icon up in this bitch
  image = [NSImage imageNamed:@"pause-icon"];
  pauseIcon_ = [CALayer layer];
  pauseIcon_.contents = image;
  pauseIcon_.autoresizingMask = kCALayerMinXMargin
                              | kCALayerMaxXMargin
                              | kCALayerMinYMargin
                              | kCALayerMaxYMargin;
  pauseIcon_.contentsGravity = kCAGravityLeft;
  pauseIcon_.bounds =
      NSMakeRect(0.0, 0.0, image.size.width, image.size.height);
  pauseIcon_.opacity = 0.0;
  [self.layer addSublayer:pauseIcon_];
  
  // If YES: multiplayer, if NO: computer opponent
  self.localMultiplayer = [[NSUserDefaults standardUserDefaults] boolForKey:@"localMultiplayer"];
  
  // To avoid initial sound loading delay
  NSSound *sound = [NSSound soundNamed:@"Pop"];
  sound.volume = 0.0;
  [sound play];
    
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (BOOL)localMultiplayer {
  return !remotePlayerPaddle_;
}


- (void)setLocalMultiplayer:(BOOL)localMultiplayer {
  if (localMultiplayer) {
    remotePlayerPaddle_ = nil;
    if (aiPlayer_) {
      [aiPlayer_ release];
      aiPlayer_ = nil;
    }
  } else {
    remotePlayerPaddle_ = localPlayerPaddle_ == rightPaddle_ ? leftPaddle_
                                                             : rightPaddle_;
    // Create AI player
    id oldPlayer = aiPlayer_;
    aiPlayer_ = [[MGPongAIPlayer alloc] initWithPaddle:remotePlayerPaddle_
                                                inGame:self];
    [oldPlayer release];
  }
  [[NSUserDefaults standardUserDefaults] setBool:self.localMultiplayer
                                          forKey:@"localMultiplayer"];
  [self newGame:self];
}


- (void)_resumeUpdatingWithDelayId:(NSTimer*)timer {
  if (timer != animationTimer_) {
    // this timer was aborted
    NSLog(@"this timer was aborted");
    [timer release];
    return;
  }
  
  // remove "pending" animation from ball
  [ball_ removeAllAnimations];
  
  // Go!
  self.isWarmingUp = NO;
}


- (void)resumeUpdating {
  if (animationTimer_)
    return;
  [self hideBanner:self];
  NSMethodSignature *sig = 
      [isa instanceMethodSignatureForSelector:@selector(update)];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
  [inv setSelector:@selector(update)];
  [inv setTarget:self];
  self.isWarmingUp = YES;
  timeOfLastUpdate_ = mach_absolute_time();
  animationTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0
                                                 invocation:inv
                                                    repeats:YES];
  [animationTimer_ retain];
  
  // Seconds delay until game commence
  const CGFloat startDelay = 1.0;
  
  // Add "pending" animation to ball
  
  CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
  anim.duration = startDelay / 4.0;
  anim.fromValue = [NSNumber numberWithFloat:1.0];
  anim.toValue = [NSNumber numberWithFloat:0.5];
  anim.autoreverses = YES;
  anim.repeatCount = HUGE_VALF;
  anim.timingFunction = [CAMediaTimingFunction functionWithName:
                         kCAMediaTimingFunctionEaseInEaseOut];
  [ball_ addAnimation:anim forKey:@"animateOpacity"];
  
  CGPoint startPosition = ball_.position;
  CGPoint nextPosition = [ball_ positionInFuture:startDelay * 0.2];
  
  // Move paddles to the next position if playing against computer
  if (!self.localMultiplayer) {
    rightPaddle_.position = CGPointMake(rightPaddle_.position.x, nextPosition.y);
    leftPaddle_.position = CGPointMake(leftPaddle_.position.x, nextPosition.y);
  }
  
  if (ceil(startPosition.x * 1000.0) != ceil(nextPosition.x * 1000.0)) {
    anim = [CABasicAnimation animationWithKeyPath:@"position.x"];
    anim.duration = startDelay / 4.0;
    anim.fromValue = [NSNumber numberWithFloat:startPosition.x];
    anim.toValue = [NSNumber numberWithFloat:nextPosition.x];
    anim.autoreverses = YES;
    anim.repeatCount = HUGE_VALF;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:
                           kCAMediaTimingFunctionEaseIn];
    [ball_ addAnimation:anim forKey:@"animatePositionX"];
  }
  if (ceil(startPosition.y * 1000.0) != ceil(nextPosition.y * 1000.0)) {
    anim = [CABasicAnimation animationWithKeyPath:@"position.y"];
    anim.duration = startDelay / 4.0;
    anim.fromValue = [NSNumber numberWithFloat:startPosition.y];
    anim.toValue = [NSNumber numberWithFloat:nextPosition.y];
    anim.autoreverses = YES;
    anim.repeatCount = HUGE_VALF;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:
                           kCAMediaTimingFunctionEaseIn];
    [ball_ addAnimation:anim forKey:@"animatePositionY"];
  }
  
  
  // Start timer after 1 second to allow players to prepare
  [self performSelector:@selector(_resumeUpdatingWithDelayId:)
             withObject:animationTimer_
             afterDelay:startDelay];
}


- (void)pauseUpdating {
  if (!animationTimer_)
    return;
  [animationTimer_ invalidate];
  [animationTimer_ release];
  animationTimer_ = nil;
  
  // remove any animations from the ball
  [ball_ removeAllAnimations];
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
  if (!isWarmingUp_) {
    [ball_ update:period];
  }
  
  // Update AI player
  if (aiPlayer_) {
    [aiPlayer_ updateWithPeriod:period ball:ball_];
  }
}


- (void)updateVerticalDivider {
  // Vertical divider visualizes score
  CGSize size = self.layer.bounds.size;
  CGFloat centerX = size.width / 2.0;
  CGFloat x = round(centerX + (score_ * centerX));
  
  [CATransaction begin];
  [CATransaction setDisableActions:NO];
  vDividerLayer_.frame = CGRectMake(x, 0.0, 1.0, size.height);
  [CATransaction commit];
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


- (CGFloat)score {
  return score_;
}


- (void)setScore:(CGFloat)score {
  score_ = score;
  //NSLog(@"score: %f", score);
  if (score_ >= 0.98) {
    [self showBanner:@"winner-banner-left" duration:0.0];
    isInJustWonState_ = YES;
    [self newGame:self];
  } else if (score_ <= -0.98) {
    [self showBanner:@"winner-banner-right" duration:0.0];
    isInJustWonState_ = YES;
    [self newGame:self];
  } else {
    [self updateVerticalDivider];
  }
}


- (void)ball:(MGPongBallLayer*)ball hitPaddle:(MGPongPaddleLayer*)paddle {
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enableSound"]) {
    NSSound *sound = [NSSound soundNamed:@"Pop"];
    sound.volume = 1.0;
    // TODO: play on right or left speaker only
    [sound play];
  }
}


- (void)ball:(MGPongBallLayer*)ball hitWallBehindPaddle:(MGPongPaddleLayer*)paddle {
  if (paddle == leftPaddle_) {
    self.score -= 0.1;
  } else {
    self.score += 0.1;
  }
  [self resetGame:self];
  waitingToStartGame_ = NO;
  [self performSelector:@selector(resetGame:) withObject:self afterDelay:0.5];
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enableSound"])
    [[NSSound soundNamed:@"Blow"] play];
}


- (void)ball:(MGPongBallLayer*)ball hitVerticalWallOnTop:(BOOL)topWall {
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enableSound"]) {
    NSSound *sound = [NSSound soundNamed:@"Pop"];
    sound.volume = 0.1;
    [sound play];
  }
}


- (void)setFrame:(NSRect)frame {
  if (baseSize_.width == 0.0) {
    // Record initial frame
    baseSize_ = frame.size;

    // Reset game to initial state
    [super setFrame:frame];
    [self newGame:self];
  } else {
    [super setFrame:frame];
  }
  
  // Update vertical dividers
  leftDividerLayer_.frame = CGRectMake(0.0, 0.0, 1.0, frame.size.height);
  rightDividerLayer_.frame = CGRectMake(frame.size.width-1.0, 0.0,
                                        1.0, frame.size.height);
  [self updateVerticalDivider];
}


- (void)hideBanner:(id)sender {
  if (sender && [sender isKindOfClass:[NSNumber class]] &&
      bannerTimerId_ != [(NSNumber*)sender longValue]) {
    // invalid/expired timer
    return;
  }
  banner_.opacity = bannerDestinationOpacity_ = 0.0;
}


- (void)showBanner:(NSString*)imageName duration:(NSTimeInterval)duration {
  banner_.contents = [NSImage imageNamed:imageName];
  banner_.opacity = bannerDestinationOpacity_ = 1.0;
  if (duration > 0.0) {
    ++bannerTimerId_;
    NSNumber *timerId = [NSNumber numberWithLong:bannerTimerId_];
    [self performSelector:@selector(hideBanner:) withObject:timerId afterDelay:duration];
  }
}


- (void)newGame:(id)sender {
  self.score = 0.0;
  
  // Show "you" banner if no banner is visible
  if (!isInJustWonState_) {
    if (!remotePlayerPaddle_) {
      [self showBanner:@"you-banner-2locals" duration:0.0];
    } else if (localPlayerPaddle_ == rightPaddle_) {
      [self showBanner:@"you-banner-right" duration:4.0];
    } else {
      [self showBanner:@"you-banner-left" duration:4.0];
    }
  }
  
  [self resetGame:sender];
}


- (void)resetGame:(id)sender {
  // Reset things to their initial positions
  NSSize currentSize = self.bounds.size;
  CGFloat paddleCenterY =
      (currentSize.height - rightPaddle_.bounds.size.height) / 2.0;
  
  // remove any animations from the ball
  [ball_ removeAllAnimations];
  
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
  [ball_ resetBasedOnCurrentScore:score_];
  
  // Now waiting for a player to move in order to start the game
  waitingToStartGame_ = YES;
  [self pauseUpdating];
  
  [CATransaction commit];
}


- (void)startGame:(id)sender {
  // Triggered at first user interaction after the game was reset
  waitingToStartGame_ = NO;
  isInJustWonState_ = NO;
  [self resumeUpdating];
}


- (void)quit:(id)sender {
  [NSApp terminate:sender];
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
    case 'f': // Cmd+F = toggle fullscreen
      if ([NSEvent modifierFlags] & NSCommandKeyMask) {
        [self toggleFullscreen:self];
        return;
      }
      break;
    /*case 'r': // Cmd+R = reset game
      if ([NSEvent modifierFlags] & NSCommandKeyMask) {
        [self resetGame:self];
        return;
      }
      break;*/
    case 'n': // Cmd+N = new game
      if ([NSEvent modifierFlags] & NSCommandKeyMask) {
        [self newGame:self];
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
    default:
      //NSLog(@"keyUp: %d", ch);
      break;
  }
  [super keyUp:ev];
}


- (void)toggleComputerOpponent:(id)sender {
  self.localMultiplayer = !self.localMultiplayer;
}

- (void)toggleEnableSound:(id)sender {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud setBool:![ud boolForKey:@"enableSound"] forKey:@"enableSound"];
}


- (void)mouseDown:(NSEvent *)event {
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Hello"];
  [menu addItemWithTitle:@"New game" action:@selector(newGame:) keyEquivalent:@""];
  
  [[menu addItemWithTitle:@"2-player mode"
                  action:@selector(toggleComputerOpponent:)
           keyEquivalent:@""] setState:self.localMultiplayer];
  
  [[menu addItemWithTitle:@"Play sounds"
                   action:@selector(toggleEnableSound:)
            keyEquivalent:@""] setState:[[NSUserDefaults standardUserDefaults]
                                         boolForKey:@"enableSounds"]];
  
  [menu addItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@""];
  
  NSPoint wp = {0, self.bounds.size.height + 4.0};
  wp = [self convertPoint:wp toView:nil];
  NSEvent* ev = [NSEvent mouseEventWithType:event.type
                                   location:wp
                              modifierFlags:0 timestamp:[event timestamp]
                               windowNumber:[event windowNumber]
                                    context:[event context]
                                eventNumber:[event eventNumber]
                                 clickCount:[event clickCount]
                                   pressure:[event pressure]];
  [NSMenu popUpContextMenu:menu withEvent:ev forView:self];
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
  self.layer.opacity = 1.0;
  leftPaddle_.opacity = 1.0;
  rightPaddle_.opacity = 1.0;
  ball_.opacity = 1.0;
  vDividerLayer_.opacity = 1.0;
  banner_.opacity = bannerDestinationOpacity_;
}

- (void)windowDidResignKey:(NSNotification *)notification {
  [self pauseUpdating];
  pauseIcon_.opacity = 1.0;
  self.layer.opacity = 0.5;
  leftPaddle_.opacity = 0.0;
  rightPaddle_.opacity = 0.0;
  ball_.opacity = 0.0;
  vDividerLayer_.opacity = 0.0;
  banner_.opacity = 0.0;
}

@end
