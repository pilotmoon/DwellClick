// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCClick.h"

@interface DCSoundController : NSObject {
	NSSound *sounds[DCClickTypeMax];
}

+ (DCSoundController *)sharedInstance;

- (void)loadSoundScheme;
- (void)playSoundForClickType:(DCClickType)type;

@end
