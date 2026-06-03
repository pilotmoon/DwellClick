// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

NSString * DCPrefsClicksPanelClassic = @"ClicksPanelClassic";

#import "DCNewClicksPanel.h"
#import "DCNewClicksPanelButton.h"
#import "DCNewClicksPanelBackgroundView.h"
#import "DCNewClicksPanelBorderView.h"

@implementation DCNewClicksPanel
@synthesize panelEnabled;

- (id)init
{
    self=[super initWithContentRect:NSZeroRect
					 styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask|NSUtilityWindowMask
					   backing:NSBackingStoreBuffered
						 defer:NO];
    if (!self) return nil;
	
    // set content view
    [self setContentView:[[DCNewClicksPanelBackgroundView alloc] initWithFrame:NSZeroRect]];
    
    // add border view
    borderView=[[DCNewClicksPanelBorderView alloc] initWithFrame:NSZeroRect];
    [borderView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [[self contentView] addSubview:borderView];

    
    [self setFloatingPanel:YES];
	[self setOpaque:NO];
	[self setBackgroundColor:[NSColor clearColor]];
    [self setMovableByWindowBackground:YES];
    [self setLevel:NSStatusWindowLevel];
    
    [self bind:@"panelEnabled" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.AutoClickOn" options:nil];
    return self;
}

- (NSButton *)buttonWithFrame:(NSRect)frame
{
    NSButton *result=[[DCNewClicksPanelButton alloc] initWithFrame:frame];    
    [result setButtonType:NSPushOnPushOffButton];
    [result setBezelStyle:NSTexturedSquareBezelStyle];
    [[result cell] setImageScaling:NSImageScaleProportionallyDown];
    [result setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin];
    return result;
}

- (void)resetBorder
{
    [borderView setFrame:[(NSView *)[self contentView] frame]];
	[[self contentView] addSubview:borderView positioned:NSWindowAbove relativeTo:nil];    
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
