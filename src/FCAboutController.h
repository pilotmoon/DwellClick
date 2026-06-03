// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NMSugarButton.h"
@interface FCAboutController : NSWindowController {
	IBOutlet NSView *contents;
	NSNib *nib;
    NSArray *topLevelObjects;
}
- (IBAction)closeAboutWindow:(id)sender;
@end
