// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMPopupWindowBackgroundView.h"
#import "NMPopupWindow.h"

@implementation NMPopupWindowBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];
	// the window rect
	NSRect windowRect=[self bounds];
	
	// add clip
	[[[self ownerWindow] nubWindowPath] addClip];

	// fill background
	[[NMPopupWindow popupBackgroundColor] set];
	NSRectFill(windowRect);
    [NSGraphicsContext restoreGraphicsState];
}

// hit test for accessibility
- (NSView *)hitTest:(NSPoint)aPoint
{
    for (NSView *sv in [self subviews]) {
        NSRect br=[sv frame];
        if (NSPointInRect(aPoint, br)) {
            if ([sv isKindOfClass:[NSButton class]]) {
                return sv;
            }
        }
    }
    return [super hitTest:aPoint];
}

@end
