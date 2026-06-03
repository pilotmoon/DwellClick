// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

@class DCClickEvent, DCFlagGroup, DCMouseTap;

@interface DCMouseClicker : NSObject {
	CGEventType downType;
	CGEventType upType;
	CGEventType dragType;
	CGEventFlags eventFlags;
	DCFlagGroup *modifierController;
	DCMouseTap *tap;
}

+ (id)leftClickerWithModifierController:(DCFlagGroup *)modifierController
									tap:(DCMouseTap *)aTap;
+ (id)rightClickerWithModifierController:(DCFlagGroup *)modifierController
									 tap:(DCMouseTap *)aTap;
+ (id)controlClickerWithModifierController:(DCFlagGroup *)modifierController
                                       tap:(DCMouseTap *)aTap;
+ (id)optionClickerWithModifierController:(DCFlagGroup *)modifierController
                                      tap:(DCMouseTap *)aTap;
+ (id)commandClickerWithModifierController:(DCFlagGroup *)modifierController
                                       tap:(DCMouseTap *)aTap;
+ (id)shiftClickerWithModifierController:(DCFlagGroup *)modifierController
									 tap:(DCMouseTap *)aTap;

- (id)initWithDownType:(CGEventType)aDownType
				upType:(CGEventType)anUpType
			  dragType:(CGEventType)aDragType
			eventFlags:(CGEventFlags)aEventFlags
	modifierController:(DCFlagGroup *)aModifierController
				   tap:(DCMouseTap *)aTap;

- (void)clickWithEvent:(DCClickEvent *)event;
- (void)doubleClickWithEvent:(DCClickEvent *)event;
- (void)tripleClickWithEvent:(DCClickEvent *)event;
- (void)dragBeginWithEvent:(DCClickEvent *)event;
- (void)dragEndWithEvent:(DCClickEvent *)event;

@end
