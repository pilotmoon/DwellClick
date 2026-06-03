// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMBubbleCloseButton.h"
#import "NSImage+NMCopySize.h"

@implementation NMBubbleCloseButton

- (void)setImagesForFrame:(NSRect)frame
{
    NSImage *ximage=[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"NM_XIcon"]];
    self.tintColor=[NSColor grayColor];
    [[self cell] setImage:ximage];
    [[self cell] setAlternateImage:ximage];
}

- (id)initWithFrame:(NSRect)frameRect
{    
	self=[super initWithFrame:frameRect];
	if (self) {
        [self setImagesForFrame:frameRect];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if(self) {
        [self setImagesForFrame:self.frame];
	}
	return self;
}


@end
