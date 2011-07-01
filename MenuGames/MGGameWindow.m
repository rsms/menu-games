//
//  MGGameWindow.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGGameWindow.h"
#import "MGConstants.h"
#import <Carbon/Carbon.h>


@implementation MGGameWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  if (!(self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) return nil;

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemUIModeChanged:) name:MGSystemUIModeChangedNotification object:nil];
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)systemUIModeChanged:(NSNotification*)n {
  unsigned int mode = [(NSNumber*)[[n userInfo] objectForKey:@"mode"] unsignedIntValue];
  BOOL someAppIsFullscreen = (mode == kUIModeAllHidden || mode == kUIModeAllSuppressed);
  if (someAppIsFullscreen && ![[self contentView] isInFullScreenMode]) {
    // Some other app went fullscreen -- hide ourselves
    [self setCanHide:YES];
    [NSApp hide:self];
  } else if (!someAppIsFullscreen && ![self isVisible]) {
    // Another app went from being fullscreen to no longer being fullscreen
    // and we are hidden -- reveal ourselves
    [NSApp unhideWithoutActivation];
    [self setCanHide:NO];
  }
}

- (BOOL)canBecomeKeyWindow {
  return YES;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}


@end
