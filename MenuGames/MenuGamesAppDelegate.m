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
#import "MGConstants.h"
#import <Carbon/Carbon.h>


EventHandlerRef g_appEventHandler;


static OSStatus handleAppEvent(EventHandlerCallRef myHandler,
                               EventRef event,
                               void* userData) {
  UInt32 mode = 0;
  OSStatus status = GetEventParameter(event,
                                      kEventParamSystemUIMode,
                                      typeUInt32,
                                      NULL,
                                      sizeof(UInt32),
                                      NULL,
                                      &mode);
  if (status != noErr)
    return status;
  [[NSNotificationCenter defaultCenter] postNotificationName:MGSystemUIModeChangedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:mode] forKey:@"mode"]];
  // e.g. to test for fullscreen changes:
  // BOOL isFullscreen = mode == kUIModeAllHidden
  return noErr;
}


static void registerForAppEvents() {
  // Fullscreen detection
  EventTypeSpec events[] = {{kEventClassApplication, kEventAppSystemUIModeChanged}};
  OSStatus status = InstallApplicationEventHandler(NewEventHandlerUPP(handleAppEvent),
                                                   GetEventTypeCount(events),
                                                   events,
                                                   nil,
                                                   &g_appEventHandler);
  if (status) NSLog(@"WARN: Failed to register for carbon app events");
  
  // Check if the user is in presentation mode initially.
  //SystemUIMode currentMode;
  //GetSystemUIMode(&currentMode, NULL);
  //fullscreen_ = currentMode == kUIModeAllHidden;
}





@implementation MenuGamesAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  statusItem_ = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  NSView *emptyView =
      [[[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 50.0, 21.0)] autorelease];
  [statusItem_ setView:emptyView];
  [statusItem_ retain];
  [statusItem_ setEnabled:YES];
  
  // Create window
  gameWindow_ = [[MGGameWindow alloc] initWithContentRect:[self statusItemFrame]
                                                styleMask:NSBorderlessWindowMask
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
  MGPongView *pongView = [[[MGPongView alloc] initWithFrame:NSZeroRect] autorelease];
  [pongView setWantsLayer:YES];
  [gameWindow_ setContentView:pongView];
  [gameWindow_ setLevel:NSStatusWindowLevel];
  [gameWindow_ setCanHide:NO];
  //[gameWindow_ setBackgroundColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.1]];
  [gameWindow_ setBackgroundColor:[NSColor clearColor]];
  [gameWindow_ setOpaque:NO];
  [gameWindow_ setDelegate:pongView];
  [gameWindow_ setInitialFirstResponder:pongView];
  [gameWindow_ makeKeyAndOrderFront:self];
  [gameWindow_ orderFrontRegardless];
  
  // Needed when LSUIElement==YES
  [NSApp activateIgnoringOtherApps:YES];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(statusItemWindowDidMove:)
                                               name:NSWindowDidMoveNotification
                                             object:[emptyView window]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(statusItemWindowDidMove:)
                                               name:NSWindowDidChangeScreenNotification
                                             object:[emptyView window]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(statusItemWindowDidMove:)
                                               name:NSWindowDidMoveNotification
                                             object:[emptyView window]];
  
  registerForAppEvents();
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
