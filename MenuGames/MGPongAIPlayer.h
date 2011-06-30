//
//  MGPongAIPlayer.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGPongPlayer.h"

@class MGPongPaddleLayer;

@interface MGPongAIPlayer : MGPongPlayer {
  CGFloat directionY_;
}

- (id)initWithPaddle:(MGPongPaddleLayer*)paddleLayer;

- (void)updateWithPeriod:(NSTimeInterval)period
                    ball:(MGPongBallLayer*)ball;

@end
