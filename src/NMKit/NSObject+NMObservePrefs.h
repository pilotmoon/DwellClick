// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

@interface NSObject (NMObservePrefs)
- (void)observePrefsKey:(NSString *)key options:(NSKeyValueObservingOptions)options;
- (void)observePrefsKey:(NSString *)key;
- (void)stopObservingPrefsKey:(NSString *)key;
@end
