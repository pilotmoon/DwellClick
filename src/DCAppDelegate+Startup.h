// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCAppDelegate.h"

@interface DCAppDelegate (Startup)

+ (BOOL)isBetaExpired;
+ (BOOL)isAlreadyRunning;
- (BOOL)testVersionUpgraded;
- (BOOL)testFirstRun;
@end
