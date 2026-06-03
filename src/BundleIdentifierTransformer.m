// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "BundleIdentifierTransformer.h"


@implementation BundleIdentifierTransformer

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
	NSString *path=[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:(NSString *)value];
	if (path) {
		return [[NSFileManager defaultManager] displayNameAtPath:path];
	}
	else {
        if (value) {
            return [NSString stringWithFormat:@"Unknown: %@", value];
        }
        else {
            return @"";
        }
	}
}

@end
