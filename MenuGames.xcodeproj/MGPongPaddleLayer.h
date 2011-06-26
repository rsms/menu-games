//
//  MGPongPaddleLayer.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class MGPongView;

@interface MGPongPaddleLayer : CALayer {
  int direction_;
  int lastUpdatedDirection_;
  CGFloat previousY_;
  MGPongView *gameView_;
}

@property (nonatomic) int direction;
@property (retain) MGPongView *gameView;
@property (readonly) CGRect presentationFrame;

@end
