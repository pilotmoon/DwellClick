// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

@class DCEngine, DCClick, NMPoint, DCUIState, DCClickEvent;

@interface DCClickIntelligence : NSObject {
	NSSet *resizers;
	NSMutableSet *apps;
	NSSet *quickDragDisallowedRoles;
	NSString *lastBlockReason;
	NSSet *mouseMovingApps; // apps which move the mouse and whose moves should be ignored
}
@property (readonly) NSString *lastBlockReason;

- (BOOL)activeAppIsBlocked;
- (DCClick *)specialClickWithEvent:(DCClickEvent *)event;
- (BOOL)canClickWithEvent:(DCClickEvent *)event;
- (BOOL)canQuickDragWithEvent:(DCClickEvent *)event;
- (BOOL)wouldOneFingerBlock:(BOOL)dragging;

@end

