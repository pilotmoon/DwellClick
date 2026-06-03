// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCFlagGroup.h"

@implementation DCFlagGroup
@synthesize flags;

- (void)twiddleFlags:(CGEventFlags)mask state:(BOOL)state
{
	if (state) {
		self.flags |= mask;
	}
	else {
		self.flags &= ~mask;
	}
}

- (BOOL)isNoSelection
{
	return self.flags==0;
}

- (void)setNoSelection
{
	self.flags=0;
}

+ (NSSet *)keyPathsForValuesAffectingNoSelection
{
	return [NSSet setWithObject:@"flags"];
}

@end
