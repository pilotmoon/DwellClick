// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "ActionNameTransformer.h"


@implementation ActionNameTransformer

- (id)init
{
	self=[super init];
	displayNames=((NSDictionary *)[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]])[@"DisplayNames"];
	return self;
}

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
	//NMLogInfo(@"TX %@", value);
	NSString *name=displayNames[value];
	return name?name:value;
}

@end
