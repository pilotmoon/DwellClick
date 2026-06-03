// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCTouchMonitor.h"
#import "DCEngine.h"
#import "DCConstants.h"

NSUInteger DCTouchMonitorFingers=0;
NSUInteger DCTouchMonitorMaxFingers=0;
static NSMutableSet *_touches=nil;

BOOL DCTouchMonitorTouchesInfoAvailable(void)
{
	return [NSEvent instancesRespondToSelector:@selector(touchesMatchingPhase:inView:)];
}

void DCTouchMonitorReset(void)
{
    DCTouchMonitorFingers=0;
    _touches=[NSMutableSet set];
}

void DCTouchMonitorUpdateWithEvent(NSEvent *event)
{
    // count fingers currently on the pad
    NSSet *touching=[event touchesMatchingPhase:NSTouchPhaseTouching inView:nil];
    if ([touching count]>0) {
        [_touches removeAllObjects]; // avoid stale data
        for (NSTouch *touch in touching) {
            [_touches addObject:[touch identity]];
        }
    }
    
    // subtract fingers removed from the pad
    NSSet *ended=[event touchesMatchingPhase:NSTouchPhaseEnded|NSTouchPhaseCancelled inView:nil];
    for (NSTouch *touch in ended) {
        [_touches removeObject:[touch identity]];
    }
    
    DCTouchMonitorFingers=[_touches count];
    if (DCTouchMonitorFingers>DCTouchMonitorMaxFingers) {
        DCTouchMonitorMaxFingers=DCTouchMonitorFingers;
    }
}

void DCTouchMonitorHandleTappedEvent(CGEventRef cgEvent)
{
	NSEvent *event=[NSEvent eventWithCGEvent:cgEvent];
	if (event) {
		DCTouchMonitorUpdateWithEvent(event);
	}
}

