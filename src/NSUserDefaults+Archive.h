// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>


@interface NSUserDefaults(Archive) 

- (void)setArchivedObject:(id)aObject forKey:(NSString *)aKey;

- (id)archivedObjectForKey:(NSString *)aKey;

@end
