//
//  MGPongBallLayer.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class MGPongView;

@interface MGPongBallLayer : CALayer {
  MGPongView *gameView_;
  CGPoint velocity_;
}

@property (retain) MGPongView *gameView;

- (CGPoint)positionInFuture:(NSTimeInterval)period;

- (void)update:(NSTimeInterval)period;
- (void)resetBasedOnCurrentScore:(CGFloat)score;

@end
