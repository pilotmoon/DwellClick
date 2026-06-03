// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCUniqueSelection.h"
#import "DCSelectionGroup.h"

@implementation DCSelectionGroup
@synthesize delegate, selectedItem;

- (id)init
{
	self=[super init];
	self.selectedItem=[self noSelectionObject];
	return self;
}

- (DCUniqueSelection *)noSelectionObject
{
	return nil; // override in subclass if desired
}

- (BOOL)isNoSelection
{
	return self.selectedItem==[self noSelectionObject];
}

- (void)setNoSelection
{
	self.selectedItem=[self noSelectionObject];	
}

+ (NSSet *)keyPathsForValuesAffectingNoSelection
{
	return [NSSet setWithObject:@"selectedItem"];
}

@end
