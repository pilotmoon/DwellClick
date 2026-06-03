// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NSObject+NMObservePrefs.h"


@implementation NSObject (NMObservePrefs)

- (void)observePrefsKey:(NSString *)key options:(NSKeyValueObservingOptions)options
{
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:[@"values." stringByAppendingString:key]
																 options:options
																 context:nil];
}

- (void)observePrefsKey:(NSString *)key
{
	[self observePrefsKey:key options:0];
}

- (void)stopObservingPrefsKey:(NSString *)key
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self
                                                                 forKeyPath:[@"values." stringByAppendingString:key]];
}

@end
