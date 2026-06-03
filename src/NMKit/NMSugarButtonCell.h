// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

@interface NMSugarButtonCell : NSButtonCell {
	NSColor *backgroundColor;
	NSColor *textColor;
    NSColor *glowColor;
}
@property (retain) NSColor *backgroundColor;
@property (retain) NSColor *textColor;
@property (retain) NSColor *glowColor;

@end
