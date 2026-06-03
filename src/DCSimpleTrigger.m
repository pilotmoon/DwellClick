// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCSimpleTrigger.h"

@implementation DCSimpleTrigger
@synthesize name;

- (id)initWithName:(NSString *)aName
			target:(id)aTarget
		  selector:(SEL)aSelector
{
	if (!(self = [super init])) return nil;
	name=aName;
	target=aTarget;
	selector=aSelector;
	return self;
}

- (void)performTriggeredAction
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[target performSelector:selector];
#pragma clang diagnostic pop
}

- (void)perform:(NSScriptCommand *)command
{
	[self performTriggeredAction];
}

- (void)performTriggeredActionFromKeyboard
{
	[self performTriggeredAction];
}

- (void)performTriggeredActionFromPopupWithLocation:(NMPoint *)location
{
	[self performTriggeredAction];
}

@end
