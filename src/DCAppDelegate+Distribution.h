// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

@interface DCAppDelegate (Distribution) 

+ (BOOL)isBetaReleaseChannel;

- (void)distributionInit;
- (void)distributionFirstRun;
- (void)distributionVersionUpgrade;
- (void)distributionWillFinishLaunching;
- (void)distributionDidFinishLaunching;
- (void)distributionDidClick;

@end
