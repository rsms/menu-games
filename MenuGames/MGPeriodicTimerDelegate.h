//
//  MGPeriodicTimerDelegate.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MGPeriodicTimerDelegate <NSObject>
- (void)periodicTimerTick;
@end


