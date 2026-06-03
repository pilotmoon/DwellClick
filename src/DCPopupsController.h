// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NMPopupController.h"
@class DCClickEvent;

typedef enum {
	DCPopupButtonSetStandard,
	DCPopupButtonSetStandardWithLock,
	DCPopupButtonSetShift,
	DCPopupButtonSetControl,
    DCPopupButtonSetOption,
    DCPopupButtonSetCommand,
    DCPopupButtonSetNone,
	DCPopupButtonSetMax
} DCPopupButtonSetIdentifier;

@class DCClick, DCClickEvent, DCUIState, NMPopupWindow, NMPoint;

@interface DCPopupsController : NMPopupController
{	
    // buttons
    NSDictionary *availableButtons;
    NSArray *clickButtons;
	NSArray *alternativeClickButtons;
    NSArray *clickButtonsShift;
    NSArray *clickButtonsControl;
    NSArray *clickButtonsOption;
    NSArray *clickButtonsCommand;
    DCPopupButtonSetIdentifier buttonSet;
}

@property (assign) DCPopupButtonSetIdentifier buttonSet;

- (id)initWithClictionary:(NSDictionary *)clictionary;

- (BOOL)mouseEventDuringOverride:(CGEventRef)event type:(CGEventType)type location:(CGPoint)location;

- (void)engineWillClickWithEvent:(DCClickEvent *)event;
- (void)engineDidClickWithEvent:(DCClickEvent *)event;
- (void)clickCompletedWithEvent:(DCClickEvent *)event;

+ (DCPopupButtonSetIdentifier)buttonSetForFlags:(CGEventFlags)flags;


@end
