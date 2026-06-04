// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NMPopupController.h"
@class DCClickEvent;

@class DCClick, DCClickEvent, DCUIState, NMPopupWindow, NMPoint;

@interface DCPopupsController : NMPopupController
{	
    // buttons
    NSArray *clickButtons;
}

- (id)initWithClictionary:(NSDictionary *)clictionary;

- (BOOL)mouseEventDuringOverride:(CGEventRef)event type:(CGEventType)type location:(CGPoint)location;

- (void)engineWillClickWithEvent:(DCClickEvent *)event;
- (void)engineDidClickWithEvent:(DCClickEvent *)event;
- (void)clickCompletedWithEvent:(DCClickEvent *)event;

@end
