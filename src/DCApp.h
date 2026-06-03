// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCAppDelegate.h"

@interface DCApplication : NSApplication

- (NSNumber*) enabled;
- (NSArray*) actions;
- (DCUniqueSelection*) selectedAction;

@property (readonly) DCEngine *engine;

@end
