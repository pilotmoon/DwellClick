// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <AppKit/AppKit.h>

@interface DCNewClicksPanel : NSPanel {
    NSView *borderView;
    BOOL panelEnabled;
}
- (NSButton *)buttonWithFrame:(NSRect)frame;
- (void)resetBorder;
@property (assign) BOOL panelEnabled;

@end
