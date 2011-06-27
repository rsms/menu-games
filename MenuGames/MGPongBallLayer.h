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
  CGFloat speed_;
  CGFloat startSpeed_;
  CGPoint velocity_;
}

@property (retain) MGPongView *gameView;

- (void)update:(NSTimeInterval)period;
- (void)reset;

@end
