#import <Cocoa/Cocoa.h>

@class MGGameWindow;

@interface MenuGamesAppDelegate : NSObject <NSApplicationDelegate> {
@private
  NSStatusItem *statusItem_;
  MGGameWindow *gameWindow_;
}

- (NSRect)statusItemFrame;
- (void)updateGameWindowFrame;

@end
