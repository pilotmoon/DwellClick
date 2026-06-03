// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#if MAC_OS_X_VERSION_MAX_ALLOWED<=MAC_OS_X_VERSION_10_5	
#import "DCTouchAPI.h"
#endif
extern NSUInteger DCTouchMonitorFingers;
extern NSUInteger DCTouchMonitorMaxFingers;

BOOL DCTouchMonitorTouchesInfoAvailable(void);
void DCTouchMonitorHandleTappedEvent(CGEventRef cgEvent);
void DCTouchMonitorReset(void);
void DCTouchMonitorUpdateWithEvent(NSEvent *event);
