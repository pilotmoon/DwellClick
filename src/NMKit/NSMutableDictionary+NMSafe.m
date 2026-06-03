// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NSMutableDictionary+NMSafe.h"

@implementation NSMutableDictionary (NMSafe)

- (NSMutableArray *)storageArrayForKey:(id)key
{
    NSMutableArray *result=self[key];
    if (key&&![result isKindOfClass:[NSMutableArray class]]) {
        result=[NSMutableArray array];
        self[key] = result;
    }
    return result;
}

- (NSMutableSet *)storageSetForKey:(id)key
{
    NSMutableSet *result=self[key];
    if (key&&![result isKindOfClass:[NSMutableSet class]]) {
        result=[NSMutableSet set];
        self[key] = result;
    }
    return result;
}

@end
