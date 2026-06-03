// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NMSugarButton.h"

@interface DCClickCounterView : NSView {
	NMSugarButton *resetButton;
	NSTimer *timer;
	NSUInteger frame;
}
- (IBAction)resetClickCounts:(id)sender;
@end
