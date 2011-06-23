//
//  MGGameWindow.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGGameWindow.h"


@implementation MGGameWindow

- (id)init {
  self = [super init];
  if (self) {
  }
  
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (BOOL)canBecomeKeyWindow {
  return YES;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}


@end
