// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
@class NMPoint;

@protocol DCTriggerable
- (void)performTriggeredAction; 
- (void)performTriggeredActionFromKeyboard;
- (void)performTriggeredActionFromPopupWithLocation:(NMPoint *)location;
- (void)perform:(NSScriptCommand*)command; // perform from script
@end
