// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCKeyedSelection.h"


@implementation DCKeyedSelection
@synthesize invert;

- (id)initWithName:(NSString *)aName object:(id)aObject keyPath:(NSString *)aKeyPath
{
	self=[super initWithName:aName];
	object=aObject;
	keyPath=aKeyPath;
	[object addObserver:self forKeyPath:keyPath options:0 context:nil];
	return self;
}

- (void)setSelected:(BOOL)state
{
	[object setValue:[NSNumber numberWithBool:invert?!state:state] forKeyPath:keyPath];
}

- (BOOL)isSelected
{
	BOOL result=[[object valueForKeyPath:keyPath] boolValue];
	return invert?!result:result;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self willChangeValueForKey:@"selected"];
	[self didChangeValueForKey:@"selected"];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"KeyedSelection: %@ (%@ %@) invert: %d", name, object, keyPath, invert];
}

@end
