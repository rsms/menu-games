//
//  MGPongPlayer.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGPongPlayer.h"
#import "MGPongPaddleLayer.h"

@implementation MGPongPlayer

- (id)init {
  if (!(self = [super init])) return nil;
  score_ = 1.0;
  return self;
}

- (void)dealloc {
  [super dealloc];
}


- (MGPongPaddleLayer*)paddleLayer {
  return paddleLayer_;
}

- (void)setPaddleLayer:(MGPongPaddleLayer*)layer {
  paddleLayer_ = layer;
  
  // Create score layer
  if (scoreLayer_) {
    [scoreLayer_ removeFromSuperlayer];
  }
  
  CALayer *gameLayer = paddleLayer_.superlayer;
  scoreLayer_ = [CALayer layer];
  scoreLayer_.backgroundColor = CGColorCreateGenericRGB(1.0, 0.1, 0.1, 1.0);
  scoreLayer_.frame = CGRectMake(0.0, 0.0, 2.0, 1.0);
  [gameLayer addSublayer:scoreLayer_];
  [gameLayer addObserver:self forKeyPath:@"bounds" options:0 context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (object == paddleLayer_.superlayer &&
      [keyPath isEqualToString:@"bounds"]) {
    // Game view bounds changed
    // Set score layer frame
    /*
     ----------------------
          =====|=====
               |
               |     
     ----------------------
     */
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    isRightPlayer_ = (paddleLayer_.frame.origin.x >
                      (paddleLayer_.superlayer.bounds.size.width / 2.0));
    if (isRightPlayer_) {
      scoreLayer_.backgroundColor = CGColorCreateGenericRGB(0.9, 0.2, 0.1, 1.0);
    } else {
      scoreLayer_.backgroundColor = CGColorCreateGenericRGB(0.2, 0.3, 0.9, 1.0);
    }
    [self updateScoreLayer];
    [CATransaction commit];
  }
}


- (void)updateScoreLayer {
  CALayer *gameLayer = paddleLayer_.superlayer;
  CGSize gameSize = gameLayer.bounds.size;
  CGFloat width = ceil(gameSize.width * 0.2) * score_;
  CGFloat height = ceil(gameSize.height * 0.05);
  static const CGFloat topMargin = 2.0;
  static const CGFloat vDividerThickness = 1.0;
  if (isRightPlayer_) {
    scoreLayer_.frame =
        CGRectMake(ceil(gameSize.width / 2.0) + vDividerThickness,
                   gameSize.height - height - topMargin,
                   width, height);
  } else {
    scoreLayer_.frame =
        CGRectMake(ceil((gameSize.width / 2.0) - width),
                   gameSize.height - height - topMargin,
                   width, height);
  }
}



- (CGFloat)score {
  return score_;
}

- (void)setScore:(CGFloat)score {
  score_ = score;
  [self updateScoreLayer];
}


@end
