// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "FCLinkView.h"
#import "DCLinks.h"

@implementation FCLinkView

- (void)mouseUp:(NSEvent *)theEvent
{
	[DCLinks openTagLink:self];
	
}
@end
