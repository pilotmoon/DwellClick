// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
@protocol DCActivation

@property (assign, getter=isActive) BOOL active;
- (void)start;
- (void)stop;

@end
