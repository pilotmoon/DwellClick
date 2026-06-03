// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCClickEvent.h"
#import "DCUIState.h"
#import "DCClick.h"
#import "DCEngine.h"
#import "DCUtils.h"
#import "DCTouchMonitor.h"
#import "NMKit/NMAppUtils.h"
#import "NMKit/NMPoint.h"

@implementation DCClickEvent
@synthesize selectedClick, uiState, source, actualClick, initialFingers, minFingers, maxFingers, initialActivePid, scrollWheelWasUsed;
@synthesize movementCausedByApp;

- (id)initWithSelectedClick:(DCClick *)click
					 source:(DCEventSourceType)aSource
			flippedLocation:(NMPoint *)aLocation;
{
	actualClick=selectedClick=click;
	source=aSource;
	uiState=[[DCUIState alloc] initWithFlippedLocation:aLocation];	
	
	// these are only valid if the source is a DWELL
	initialFingers=DCTapData->initialFingers;
	minFingers=DCTapData->minFingers;
	maxFingers=DCTapData->maxFingers;
	initialActivePid=DCTapData->initialActivePid;
	scrollWheelWasUsed=DCTapData->activitySinceRest[DCTapActivityScroll];
	movementCausedByApp=NMBundleIdForPID((pid_t)DCTapData->lastMovePid);
	
	return self;
}

- (id)initWithSelectedClick:(DCClick *)click
					 source:(DCEventSourceType)aSource
{
	return [self initWithSelectedClick:click source:aSource flippedLocation:[NMPoint currentFlippedMouseLocation]];
}

- (void)markAsComplete
{
	[[DCEngine sharedInstance] eventIsComplete:self];
}

- (void)markAsCancelled:(NSString *)reason
{
    DCTouchMonitorReset();
	NMLogInfo(@"Event Cancelled. Reason: %@", reason);
}

@end
