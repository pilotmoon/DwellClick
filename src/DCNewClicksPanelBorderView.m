// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCConstants.h"
#import "DCNewClicksPanelBorderView.h"
#import "DCClicksPanelController.h"
#import <NMKit/NMPopupWindow.h>

@implementation DCNewClicksPanelBorderView

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];

   	const NSRect windowRect=[self bounds];
    const BOOL horiz=[[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsClicksPanelStyle]==DCPanelStyleHorizontal;
    
	// the path
    const CGFloat RADIUS=8;
    NSBezierPath *boundingPath=[NSBezierPath bezierPathWithRoundedRect:windowRect xRadius:RADIUS yRadius:RADIUS];    
    [boundingPath addClip];
	
    if ([NMPopupWindow classicStyle]) {
        // draw the gradient
        NSRect gradBounds = windowRect;
        
        if (horiz) {
            gradBounds.size.height*=0.5;
            gradBounds.origin.y+=gradBounds.size.height;
        }
        else {
            gradBounds.size.width*=0.35;
        }
        [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:1.0 alpha:horiz?0.06:0.35]
                                       endingColor:[NSColor colorWithDeviceWhite:1.0 alpha:horiz?0.35:0.06]]
         drawInRect:gradBounds angle:horiz?90:0];

	
        // outer highlight line
        [[NSColor colorWithDeviceWhite:0.15 alpha:1.0] set];
        [boundingPath setLineWidth:2.0];
        [boundingPath stroke];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
