// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "ActionIconTransformer.h"
#import "DCCommon.h"

@implementation ActionIconTransformer

+ (Class)transformedValueClass
{
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	NSImage *image=[[NSImage symbolForName:value] copyWithSize:NSMakeSize(36,18)]; // sorry bit of a hack
	image.template=YES;
	return image;
}

@end
