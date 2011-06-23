//
//  MenuGamesAppDelegate.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MenuGamesAppDelegate.h"
#import "MGPongView.h"
#import "MGGameWindow.h"

@implementation MenuGamesAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  
  statusItem_ = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  NSView *emptyView =
      [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 50.0, 21.0)];
  [statusItem_ setView:emptyView];
  [statusItem_ retain];
  [statusItem_ setEnabled:YES];
  
  // Create window
  gameWindow_ = [[MGGameWindow alloc] initWithContentRect:[self statusItemFrame]
                                                styleMask:NSBorderlessWindowMask
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
  MGPongView *pongView = [[MGPongView alloc] initWithFrame:NSZeroRect];
  [gameWindow_ setContentView:pongView];
  [gameWindow_ setLevel:NSStatusWindowLevel];
  [gameWindow_ setBackgroundColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.1]];
  //[gameWindow_ setBackgroundColor:[NSColor clearColor]];
  [gameWindow_ setOpaque:NO];
  [gameWindow_ makeKeyAndOrderFront:self];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(statusItemWindowDidMove:)
                                               name:NSWindowDidMoveNotification
                                             object:[emptyView window]];
}

- (NSRect)statusItemFrame {
  return [[[statusItem_ view] window] frame];
}

- (void)updateGameWindowFrame {
  NSRect frame = [self statusItemFrame];
  // Remove menu bar shadow 1px
  frame.origin.y += 1.0;
  frame.size.height -= 1.0;
  //NSLog(@"frame.size.height %f", frame.size.height);
  [gameWindow_ setFrame:frame display:YES animate:NO];
}

- (void)statusItemWindowDidMove:(NSNotification*)n {
  [self updateGameWindowFrame];
}

@end
