//
//  MGPongAIPlayer.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGPongPlayer.h"

@class MGPongPaddleLayer, MGPongView;

@interface MGPongAIPlayer : MGPongPlayer {
  __weak MGPongView *gameView_;
  BOOL isWarmingUp_;
  CGFloat difficulty_;
}

@property (assign) BOOL isWarmingUp;
@property (assign) CGFloat difficulty;

- (id)initWithPaddle:(MGPongPaddleLayer*)paddleLayer
              inGame:(MGPongView*)gameView;

- (void)updateWithPeriod:(NSTimeInterval)period
                    ball:(MGPongBallLayer*)ball;

@end
