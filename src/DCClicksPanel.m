// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCClicksPanel.h"
#import "DCClicksPanelButton.h"

@implementation DCClicksPanel

- (id)init
{
    self=[super initWithContentRect:NSMakeRect(0, 0, 0, 0)
                          styleMask:NSTitledWindowMask|NSClosableWindowMask|NSUtilityWindowMask|NSNonactivatingPanelMask|NSHUDWindowMask
                            backing:NSBackingStoreBuffered
                              defer:YES];  
    return self;
}

- (NSButton *)buttonWithFrame:(NSRect)frame
{
    NSButton *result=[[DCClicksPanelButton alloc] initWithFrame:frame];    
    [result setButtonType:NSPushOnPushOffButton];
    [result setBezelStyle:NSTexturedSquareBezelStyle];
    [[result cell] setImageScaling:NSImageScaleProportionallyDown];
    return result;
}

- (BOOL)canBecomeKeyWindow
{
	return NO;
}

- (BOOL)canBecomeMainWindow
{
	return NO;
}

@end
