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
  MGPongPaddleLayer *paddleLayer_;
}

@property (retain, nonatomic) MGPongPaddleLayer *paddleLayer;

@end
