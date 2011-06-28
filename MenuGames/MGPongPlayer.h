//
//  MGPongPlayer.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class MGPongPaddleLayer;

@interface MGPongPlayer : NSObject {
  CGFloat score_;
  CALayer *scoreLayer_;
  MGPongPaddleLayer *paddleLayer_;
  BOOL isRightPlayer_;
}

@property (assign) CGFloat score;
@property (retain, nonatomic) MGPongPaddleLayer *paddleLayer;

- (void)updateScoreLayer;

@end
