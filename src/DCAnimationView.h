// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>


@interface DCAnimationView : NSView {
	NSMutableDictionary *timerBlocks;
}
@property (readonly) NSMutableDictionary *timerBlocks;

@end
