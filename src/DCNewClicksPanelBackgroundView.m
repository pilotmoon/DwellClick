// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCNewClicksPanelBackgroundView.h"

@implementation DCNewClicksPanelBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];

    // the window rect
	NSRect windowRect=[self bounds];
	
	// add clip
    const CGFloat RADIUS=8;
    NSBezierPath *boundingPath=[NSBezierPath bezierPathWithRoundedRect:windowRect xRadius:RADIUS yRadius:RADIUS];    
    [boundingPath addClip];
  
	// fill background
	[[NSColor colorWithDeviceWhite:0.10 alpha:1.0] set];
	NSRectFill(windowRect);
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
