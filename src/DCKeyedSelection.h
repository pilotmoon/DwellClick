// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCSelection.h"

@interface DCKeyedSelection : DCSelection {
	id object;
	NSString *keyPath;
	BOOL invert;
}

- (id)initWithName:(NSString *)name object:(id)object keyPath:(NSString *)keyPath;
@property (assign) BOOL invert;

@end
