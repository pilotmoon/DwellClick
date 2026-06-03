// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCUniqueSelection.h"
#import "DCSelectionGroup.h"

@implementation DCUniqueSelection
@synthesize group;

// designated initializer
- (id)initWithName:(NSString *)aName
			 group:(DCSelectionGroup *)aGroup;

{
	self = [super initWithName:aName];
	group=aGroup;
	return self;
}

- (void)setSelected:(BOOL)state
{
	if (state) {
		self.group.selectedItem=self;
	}
	else {
		[self.group setNoSelection];
	}
}

- (BOOL)isSelected
{
	return self.group.selectedItem==self;
}

+ (NSSet *)keyPathsForValuesAffectingSelected
{
	return [NSSet setWithObject:@"group.selectedItem"];
}

@end
