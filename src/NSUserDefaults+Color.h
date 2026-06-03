// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>


@interface NSUserDefaults(Color)

- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey;

- (NSColor *)colorForKey:(NSString *)aKey;

@end
