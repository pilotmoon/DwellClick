// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

@interface NMImageButton : NSButton {
	BOOL _mouseIn;
}
- (void)updateTrackingAreas;
@property (readonly) BOOL mouseIn;
@property (retain) NSColor *tintColor;
@end
