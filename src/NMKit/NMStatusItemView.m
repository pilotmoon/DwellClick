// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMStatusItemView.h"
#import "NMStatusItemController.h"

@implementation NMStatusItemView

- (id)initWithFrame:(NSRect)frame controller:(NMStatusItemController *)controller
{
	if(self=[super initWithFrame:frame])
	{
		_controller=controller;	
	}
	return self;
}

- (BOOL)isFlipped
{
	return NO;
}

- (void)drawRect:(NSRect)rect
{
    [_controller drawInRect:rect];
}

- (void)rightMouseDown:(NSEvent *)event
{
    [_controller doRightClickAction];
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event
{
    if ([NSEvent modifierFlags]&NSAlternateKeyMask) {
        [_controller doAlternateAction];
    }
    else if ([NSEvent modifierFlags]&NSControlKeyMask) {
        [_controller doRightClickAction];
    }
    else {
        [_controller doLeftClickAction];
    }
    [self setNeedsDisplay:YES];
}

@end
