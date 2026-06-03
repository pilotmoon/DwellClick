// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMPopupWindowBorderView.h"
#import "NMPopupWindow.h"
#import "NMCoreUtils.h"

@implementation NMPopupWindowBorderView

- (void)drawRect:(NSRect)dirtyRect
{
	// the path
	NSBezierPath *mainBgPath=[[self ownerWindow] nubWindowPath];
	
	// add the clip
	[mainBgPath addClip];

	// draw the gradient
    if ([NMPopupWindow classicStyle]) {
        NSRect gradBounds = [[self ownerWindow] boxFrame];
        gradBounds.size.height*=0.5;
        gradBounds.origin.y+=gradBounds.size.height;
        [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.06]
                                       endingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.35]]
         drawInRect:gradBounds angle:90];
        
        // outer highlight line
        [[NSColor colorWithDeviceWhite:0.1 alpha:1.0] set];
        [mainBgPath setLineWidth:2.0];
        [mainBgPath stroke];
    }
    else {
        NSRect gradBounds = [[self ownerWindow] boxFrame];
        [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.02]
                                       endingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.07]]
         drawInRect:gradBounds angle:90];
    }
}

@end
