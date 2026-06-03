// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NSUserDefaults+Archive.h"


@implementation NSUserDefaults(Archive)

- (void)setArchivedObject:(id)aObject forKey:(NSString *)aKey
{
    NSData *theData=[NSKeyedArchiver archivedDataWithRootObject:aObject];
	[self setObject:theData forKey:aKey];
}

- (id)archivedObjectForKey:(NSString *)aKey
{
    id theObject=nil;
    NSData *theData=[self dataForKey:aKey];
    if (theData != nil)
	{	
        theObject=[NSKeyedUnarchiver unarchiveObjectWithData:theData];
	}
	return theObject;
}

@end
