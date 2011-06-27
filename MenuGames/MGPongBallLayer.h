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
  CGFloat direction_; // degrees 0-360
  CGFloat directionX_;
  CGFloat directionY_;
}

@property (retain) MGPongView *gameView;

- (void)update:(NSTimeInterval)period;

@end
