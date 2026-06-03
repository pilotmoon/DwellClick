// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>


@interface NSImage(NMCopySize) 

- (NSImage *)copyWithSize:(NSSize)size colorTo:(NSColor *)color;
- (NSImage *)copyWithSize:(NSSize)size;
+ (NSImage *)blankBitmapOfSize:(NSSize)size;

@end
