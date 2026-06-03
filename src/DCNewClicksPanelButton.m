// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCNewClicksPanelButton.h"
#import "DCNewClicksPanelButtonCell.h"
#import "NMKit/NMKit.h"

@implementation DCNewClicksPanelButton
@synthesize flashState, mouseInsideButton;

+ (Class)cellClass
{
    return [DCNewClicksPanelButtonCell class];
}

- (void)flash
{
	flashState=1;
	[self setNeedsDisplay:YES];
	NMRunAsyncOnMainThreadWithDelay(0.1, ^{
		flashState=0;	
		[self setNeedsDisplay:YES];
	});
}


- (BOOL)mouseDownCanMoveWindow
{
    if ([[self cell] isEnabled]) {
        return NO;
    }
    else {
        return YES;
    }
}

@end
