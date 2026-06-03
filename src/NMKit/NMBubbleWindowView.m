// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMBubbleWindowView.h"

@implementation NMBubbleWindowView

- (BOOL)isDarkAppearance
{
    NSString *match=[self.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
    return [match isEqualToString:NSAppearanceNameDarkAqua];
}

- (void)viewDidChangeEffectiveAppearance
{
    [super viewDidChangeEffectiveAppearance];
    [self setNeedsDisplay:YES];
}

//
// drawRect:
//
// Draws the frame of the window.
//
- (void)drawRect:(NSRect)rect
{
	NSBezierPath *path = [[self ownerWindow] nubWindowPath];
	
	// the window rect
	NSRect windowRect=[self bounds];
	
	// clear rect
	[[NSColor clearColor] set];
	NSRectFill(windowRect);
	
	// fill background
    BOOL darkAppearance=[self isDarkAppearance];
	NSColor *startColor  = darkAppearance?[NSColor colorWithDeviceWhite:0.12 alpha:1.0]:[NSColor colorWithDeviceWhite:0.871 alpha:1.0];
	NSColor *endColor    = darkAppearance?[NSColor colorWithDeviceWhite:0.20 alpha:1.0]:[NSColor colorWithDeviceWhite:1.000 alpha:1.0];
	NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:startColor, 0.0, endColor, 1.0, nil];
	[gradient drawInBezierPath:path angle:90];
	
	// draw edge
	[NSGraphicsContext saveGraphicsState];
    NSColor *edgeColor=[[NSColor whiteColor] colorWithAlphaComponent:darkAppearance?0.16:0.5];
	[edgeColor set];
	[path setLineWidth:2.0];
	[path addClip];
	[path stroke];
	[NSGraphicsContext restoreGraphicsState];
}

@end
