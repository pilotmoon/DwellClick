// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCFlagSelection.h"

@interface DCFlagGroup : NSObject {
	CGEventFlags flags;
}
@property (assign) CGEventFlags flags;
@property (readonly, getter=isNoSelection) BOOL noSelection;

- (void)setNoSelection;
- (void)twiddleFlags:(CGEventFlags)mask state:(BOOL)state;

@end
