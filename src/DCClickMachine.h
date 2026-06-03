// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "DCClickControl.h"
#import "DCClick.h"
#import "DCClickEvent.h"

@interface DCClickMachine : DCSelectionGroup <DCClickControl> {
	DCClick *__strong nextDrop;
}
@property (readonly, getter=isDragging) BOOL dragging;
@property (strong) DCClick *nextDrop;

- (void)performEvent:(DCClickEvent *)event;

@end


