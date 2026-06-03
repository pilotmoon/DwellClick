// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMImageButton.h"
#import "NMImageButtonCell.h"
#import "NSImage+NMCopySize.h"

@implementation NMImageButtonCell
@synthesize tintColor=_tintColor;

- (void)drawWithFrame:(NSRect)frame inView:(NMImageButton *)controlView
{
	NSRect vframe=[controlView bounds];
	NSImage *img=[self state]?[self alternateImage]:[self image];
	
	CGFloat fraction=0.7;
    if (![self isEnabled]) {
        fraction=0.4;
    }
	else if ([self isHighlighted]) {
		fraction=0.7;
	}
	else if([controlView mouseIn]) {
		fraction=0.9;
	}
        
    if (self.tintColor) {
        NSImage *tintedImage=[img copyWithSize:vframe.size colorTo:[self.tintColor highlightWithLevel:1-fraction]];
        [tintedImage drawInRect:vframe fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    else {
        [img drawInRect:vframe fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:fraction];
    }
    
}
@end
