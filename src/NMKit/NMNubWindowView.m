// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMNubWindowView.h"


@implementation NMNubWindowView
@synthesize ownerWindow=_ownerWindow;

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if ([newWindow isKindOfClass:[NMNubWindow class]]) {
		_ownerWindow=(NMNubWindow *)newWindow;			
	}
}

@end
