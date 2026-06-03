// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCSelection.h"

// abstract class
@implementation DCSelection
@synthesize name, options;

- (id)initWithName:(NSString *)aName
{
	self = [super init];
	name=aName;
	return self;
}

- (void)setSelected:(BOOL)state
{
	[self doesNotRecognizeSelector:_cmd];
}

- (BOOL)isSelected
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (void)select:(NSScriptCommand*)command
{
	[self setSelected:YES];
}

- (void)performTriggeredAction
{
	self.selected=!self.selected; // toggle by default
}

- (void)performTriggeredActionFromKeyboard
{
	[self performTriggeredAction];
}

- (void)performTriggeredActionFromPopupWithLocation:(NMPoint *)location
{
	[self performTriggeredAction];
}

- (void)perform:(NSScriptCommand *)command
{
	[self performTriggeredAction];
}

- (void)bindToButton:(NSButton *)button
{
	[button bind:@"value" toObject:self withKeyPath:@"selected" options:nil];
}

- (NSString *)description
{
	return name ? name : [super description];
}

@end
