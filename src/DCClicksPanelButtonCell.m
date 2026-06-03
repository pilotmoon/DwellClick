// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCClicksPanelButtonCell.h"

@implementation DCClicksPanelButtonCell

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSRect imageRect=NSInsetRect(frame, frame.size.width*0.08, frame.size.height*0.08);
    [super drawImage:image withFrame:imageRect inView:controlView];
}

@end
