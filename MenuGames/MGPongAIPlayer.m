//
//  MGPongAIPlayer.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGPongAIPlayer.h"
#import "MGPongPaddleLayer.h"
#import "MGPongBallLayer.h"
#import "MGPongView.h"

#include <mach/mach.h>
#include <mach/mach_time.h>

@implementation MGPongAIPlayer

@synthesize isWarmingUp = isWarmingUp_,
            difficulty = difficulty_;


- (id)initWithPaddle:(MGPongPaddleLayer*)paddleLayer
              inGame:(MGPongView*)gameView {
  if (!(self = [super init])) return nil;
  
  gameView_ = gameView;
  self.paddleLayer = paddleLayer;
  difficulty_ = 5.9;
  
  [gameView_ addObserver:self
              forKeyPath:@"isWarmingUp"
                 options:NSKeyValueObservingOptionNew
                 context:self];
  
  return self;
}


- (void)dealloc {
  [gameView_ removeObserver:self forKeyPath:@"isWarmingUp"];
  [super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (context == self) {
    if ([keyPath isEqualToString:@"isWarmingUp"]) {
      self.isWarmingUp = [(NSNumber*)[change objectForKey:@"new"] boolValue];
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}


#define AI_USE_REACTION_PHASE 1
#define AI_USE_REACTION_PROBABILITY 1


- (void)updateWithPeriod:(NSTimeInterval)period
                    ball:(MGPongBallLayer*)ball {
  // Note: Built for controlling the left-hand side paddle. Might or might not
  // work for the right-hand paddle.
  
  CGSize gameSize = self.paddleLayer.superlayer.bounds.size;
  CGPoint ballPosition = [ball positionInFuture:period];
  CGRect paddleFrame = self.paddleLayer.frame;
  CGPoint paddlePosition = paddleFrame.origin;
  CGPoint paddleCenter = CGPointMake(paddlePosition.x + (paddleFrame.size.width / 2.0),
                                     paddlePosition.y + (paddleFrame.size.height / 2.0));


  // On Wednesday, June 29, 2011 at 18:51 PDT the system became self-aware
  // distY = pixels paddle need to move to align with ball
  // distX = distance until impact = reaction strength
  // distYC = [0-1] distance from Y center
  CGFloat distY = fabs(ballPosition.y - paddleCenter.y);
  CGFloat distX = fabs(ballPosition.x - paddleCenter.x) /
                       (gameSize.width * (isWarmingUp_ ? 1.0 : 0.5));
  CGFloat distYC = fabs((gameSize.height / 2.0) - paddleCenter.y) / (gameSize.height / 2.0);
  CGFloat distYCPower = 5.0;
  
  
#if AI_USE_REACTION_PROBABILITY
  double prob = 0.5; // probability of reacting (0=never reacts, 1=always reacts)
  srand((unsigned int)mach_absolute_time()-123);
  float r = (float)rand() / (float)RAND_MAX;
  if (r > prob) return;
#endif
  
#if AI_USE_REACTION_PHASE
  double frequency = 0.6; // Every N percentage of the updates to care about
  int phase =
      (int)ceil((double)(mach_absolute_time() % 1000000000L) / (1000000000.0 * (1.0-frequency)));
  if (phase != 1) return;
#endif
  
  // clamp distX to 1.0
  if (distX > 1.0) distX = 1.0;
  
  // random reaction speed
  srand((unsigned int)mach_absolute_time());
  float reactionQuality = (float)rand() / (float)RAND_MAX * 2.0; // [0-2]
  
  CGFloat difficulty = isWarmingUp_ ? 40.0 : difficulty_;
  difficulty = difficulty - (difficulty * distX);
  CGFloat delta = distY * difficulty * period * (distYCPower - (distYC * distYCPower)) * reactionQuality;
#if 0
  NSLog(@"%@ difficulty: %f, delta: %f, distY: %f (%f {%f, %f})",
        isWarmingUp_ ? @"WARMUP" : @"PLAYING",
        difficulty, delta, distY,
        ballPosition.y - paddleCenter.y, ballPosition.y, paddleCenter.y);
#endif
  
  if (delta < 0.0) {
    NSLog(@"WARN: %@ delta overflow avoided (%s:%d)", self, __FILE__, __LINE__);
    return;
  }
  
  // Move the paddle upwards or downwards
  if (ballPosition.y > paddleCenter.y) {
    paddlePosition.y = MIN(21.0 - paddleFrame.size.height, paddlePosition.y + delta);
  } else if (ballPosition.y < paddleCenter.y) {
    paddlePosition.y = MAX(0.0, paddlePosition.y - delta);
  }
  
  paddleFrame.origin = paddlePosition;
    
  // Set new position
  [CATransaction begin];
  //[CATransaction setDisableActions:YES];
  self.paddleLayer.frame = paddleFrame;
  [CATransaction commit];
  return;
}


@end
