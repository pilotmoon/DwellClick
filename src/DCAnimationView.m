// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCAnimationView.h"
#import "DCUtils.h"
#import "NMKit/NMBlockUtils.h"

@implementation DCAnimationView
@synthesize timerBlocks;

- (id)initWithFrame:(NSRect)frame
{
	self=[super initWithFrame:frame];
	if (self) {
		timerBlocks=[NSMutableDictionary dictionary];
	}
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NMBasicBlock block;
    block=timerBlocks[@"main"];
    if (block) {
        block();
    }
    block=timerBlocks[@"countdown"];
    if (block) {
        block();
    }
    block=timerBlocks[@"symbol"];
    if (block) {
        block();
    }
    block=timerBlocks[@"underlay"];
    if (block) {
        block();
    }

	/*for (NMBasicBlock block in [timerBlocks allValues]) {
		block();
	}*/
	// this can be handy for debugging where the system thinks the mouse is
	//[[NSColor colorWithDeviceRed:1.0 green:0 blue:0 alpha:0.5] set];
	//NSRectFill(dirtyRect);
}

@end
