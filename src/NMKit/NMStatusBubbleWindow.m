// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMStatusBubbleWindow.h"
#import "NMStatusItemController.h"



@implementation NMStatusBubbleWindow
@synthesize canBeKey;

- (void)reattach
{
    NSWindow *w=[[NMStatusItemController sharedInstance] statusItemWindow];
    if (w) {
        [self attachToWindow:w xPos:NMAttachmentOptionMid xOffset:0 yPos:NMAttachmentOptionMin yOffset:-2];
    }
}

- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(NSUInteger)windowStyle
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)deferCreation
{
	self = [super initWithContentRect:contentRect
                            styleMask:windowStyle
                              backing:bufferingType
                                defer:deferCreation];
	if (self)
	{
		[self setLevel:NSMainMenuWindowLevel+1];
        [self setFloatingPanel:YES];
        [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        [self reattach];
        self.canBeKey=YES;
    }
	return self;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (BOOL)canBecomeKeyWindow
{
    return canBeKey;
}

@end
