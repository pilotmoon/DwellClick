// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMNubWindow.h"

@interface NSBezierPath (NMNub) 

+ (NSBezierPath *)bezierPathWithNubRect:(NSRect)boxRect
								 radius:(CGFloat)radius
							nubPosition:(NMNubPosition)nubPosition
								nubSize:(CGFloat)nubSize
							  nubOffset:(CGFloat)nubOffset;
@end
