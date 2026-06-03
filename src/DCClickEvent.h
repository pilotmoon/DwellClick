// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCUIState.h"
#import "DCClick.h"

typedef enum {
	DCEventSourceDwell,
	DCEventSourceCommand,
	DCEventSourceButton,
	DCEventSourcePopup,
	DCEventSourceMax
} DCEventSourceType;

@interface DCClickEvent : NSObject {
	DCClick *selectedClick;
	DCClick *actualClick;
	DCUIState *uiState;
	DCEventSourceType source;
	NSUInteger initialFingers;
	NSUInteger minFingers;
	NSUInteger maxFingers;
	pid_t initialActivePid;
	BOOL scrollWheelWasUsed;
	NSString *movementCausedByApp;
}

@property (readonly) DCClick *selectedClick;
@property (readwrite) DCClick *actualClick;
@property (readonly) DCUIState *uiState;
@property (readonly) DCEventSourceType source;

@property (readonly) NSUInteger initialFingers;
@property (readonly) NSUInteger minFingers;
@property (readonly) NSUInteger maxFingers;
@property (readonly) pid_t initialActivePid;
@property (readonly) BOOL scrollWheelWasUsed;
@property (readonly) NSString *movementCausedByApp;

- (id)initWithSelectedClick:(DCClick *)click
					 source:(DCEventSourceType)aSource;

- (id)initWithSelectedClick:(DCClick *)click
					 source:(DCEventSourceType)aSource
			flippedLocation:(NMPoint *)aLocation;

- (void)markAsComplete;
- (void)markAsCancelled:(NSString *)reason;

@end
