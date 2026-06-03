// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

@interface NMTipWindow : NSPanel

- (void)prepareWithText:(NSString *)text andLocation:(NSPoint)location;
@end
