// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

extern NSUInteger DCTouchMonitorFingers;
extern NSUInteger DCTouchMonitorMaxFingers;

void DCTouchMonitorHandleTappedEvent(CGEventRef cgEvent);
void DCTouchMonitorReset(void);
void DCTouchMonitorUpdateWithEvent(NSEvent *event);
