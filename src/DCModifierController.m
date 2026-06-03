// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCModifierController.h"


@implementation DCModifierController

- (NSSet *)flagNames
{
    NSMutableSet *result=[NSMutableSet set];
    
    if (flags&kCGEventFlagMaskSecondaryFn) {
        [result addObject:@"Fn"];
    }
    if (flags&kCGEventFlagMaskControl) {
        [result addObject:@"Control"];
    }
    if (flags&kCGEventFlagMaskAlternate) {
        [result addObject:@"Option"];
    }
    if (flags&kCGEventFlagMaskShift) {
        [result addObject:@"Shift"];    
    }
    if (flags&kCGEventFlagMaskCommand) {
        [result addObject:@"Command"];   
    }
    
    return result;
}

- (void)twiddleFlags:(CGEventFlags)mask state:(BOOL)state
{
	if (state) {
        // disallow multiple flags
		self.flags = mask;
	}
	else {
		self.flags &= ~mask;
	}
}

@end
