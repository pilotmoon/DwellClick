// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NSUserDefaults+Color.h"

@implementation NSUserDefaults(Color)


- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey
{
    NSData *theData=[NSArchiver archivedDataWithRootObject:aColor];
    [self setObject:theData forKey:aKey];
}


- (NSColor *)colorForKey:(NSString *)aKey
{
    NSColor *theColor=nil;
    NSData *theData=[self dataForKey:aKey];
	
    if (theData != nil)
	{	
        theColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
	}
	return theColor;
}

@end
