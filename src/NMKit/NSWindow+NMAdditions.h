// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>


@interface NSWindow (NMAdditions)

- (void)prepareFadeAnimation;
- (void)animateAlphaTo:(CGFloat)alpha duration:(NSTimeInterval)interval;


@end
