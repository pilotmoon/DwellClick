// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCAppNameFormatter.h"


@implementation DCAppNameFormatter

- (NSString *)stringForObjectValue:(id)value
{
	NSString *path=[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:(NSString *)value];
	if (path) {
		return [[NSFileManager defaultManager] displayNameAtPath:path];
	}
	else {
		return [NSString stringWithFormat:@"Unknown: %@", value];
	}
}

- (NSString *)editingStringForObjectValue:(id)obj
{
	return obj;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
	*anObject=string;
	return YES;
}


@end
