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

@synthesize paddleLayer = paddleLayer_;

- (id)init {
  if (!(self = [super init])) return nil;
  return self;
}

- (void)dealloc {
  [super dealloc];
}


@end
