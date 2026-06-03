// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "SecondsTransformer.h"


@implementation SecondsTransformer


+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	return [NSString stringWithFormat:@"%0.2f seconds", [value floatValue]];
}


@end
