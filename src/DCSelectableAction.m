// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCSelectableAction.h"


@implementation DCSelectableAction

- (id)initWithName:(NSString *)aName
			 group:(DCSelectionGroup *)aGroup
			target:(id)aTarget
		  selector:(SEL)aSelector
{
	self=[super initWithName:aName group:aGroup];
	target=aTarget;
	selector=aSelector;	
	return self;
}

- (void)performWithObject:(id)obj
{
	[self.group.delegate selectionGroup:self.group willUseSelection:self withObject:obj];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[target performSelector:selector withObject:obj];
#pragma clang diagnostic pop
	[self.group.delegate selectionGroup:self.group didUseSelection:self withObject:obj];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"SelectableAction: %@ (%@ %@)", name, target, NSStringFromSelector(selector)];
}

@end
