// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCFlagSelection.h"
#import "DCFlagGroup.h"

@implementation DCFlagSelection
@synthesize group;

- (id)initWithName:(NSString *)aName
			  mask:(CGEventFlags)aMask
			 group:(DCFlagGroup *)aGroup
{
	self = [super initWithName:aName];
	NMLogInfo(@"MASK %qu", aMask);
	mask=aMask;
	group=aGroup;
	return self;	
}

- (void)setSelected:(BOOL)state
{
	[group twiddleFlags:mask state:state];
}

- (BOOL)isSelected
{
	return !!(group.flags & mask);
}

+ (NSSet *)keyPathsForValuesAffectingSelected
{
	return [NSSet setWithObject:@"group.flags"];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"FlagSelection: %@ (mask:%lld)", name, mask];
}

@end
