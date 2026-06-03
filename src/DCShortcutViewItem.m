// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCShortcutViewItem.h"

@implementation DCShortcutViewItem

- (void)tintImageViewsInView:(NSView *)view
{
    if ([view isKindOfClass:[NSImageView class]]) {
        ((NSImageView *)view).contentTintColor=[NSColor labelColor];
    }
    for (NSView *subview in view.subviews) {
        [self tintImageViewsInView:subview];
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self tintImageViewsInView:self.view];
}

@end
