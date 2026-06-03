// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "BundleIdIconTransformer.h"


@implementation BundleIdIconTransformer

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
    NSImage *result=nil;
	NSString *path=[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:value];
	if (path) {
		result=[[NSWorkspace sharedWorkspace] iconForFile:path];
		[result setSize:NSMakeSize(16, 16)];
	}
    return result;
}


@end
