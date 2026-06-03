// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMTipWindowView.h"
#import <NMKit/NMKit.h>

@implementation NMTipWindowView
@synthesize font=_font;
@synthesize text=_text;

- (void)drawRect:(NSRect)dirtyRect
{
    if (NMOSVersionCheckMavericksOrBelow()) {
        [[NSColor colorWithCalibratedRed:0.99 green:0.99 blue:0.78 alpha:1.0] set];
    }
    else {
        [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
    }
    NSRectFill([self bounds]);
    NSDictionary *attributes=@{NSFontAttributeName: self.font, NSForegroundColorAttributeName: [NSColor textColor]};
    NSRect rect=NMRectForCenteredBoxInBox([self.text sizeWithAttributes:attributes], [self bounds].size);
    [self.text drawInRect:rect
           withAttributes:attributes];
}
@end
