// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "DCActivation.h"
#import "DCMouseMonitoring.h"
#import "DCDragTypeSetting.h"

extern BOOL DCFlagTabletWasUsed;

#define INITIAL_EVENT_NUMBER (SHRT_MAX-1)
#define NUM_MOUSE_BUTTONS 32
#define MOVEMENT_A_DIST 25

// mouse bit definitions
#define MOVE_MASK (\
CGEventMaskBit(kCGEventMouseMoved)\
)

#define DRAG_MASK (\
CGEventMaskBit(kCGEventLeftMouseDragged)|\
CGEventMaskBit(kCGEventRightMouseDragged)|\
CGEventMaskBit(kCGEventOtherMouseDragged)\
)

#define DOWN_MASK (\
CGEventMaskBit(kCGEventLeftMouseDown)|\
CGEventMaskBit(kCGEventRightMouseDown)|\
CGEventMaskBit(kCGEventOtherMouseDown)\
)

#define UP_MASK (\
CGEventMaskBit(kCGEventLeftMouseUp)|\
CGEventMaskBit(kCGEventRightMouseUp)|\
CGEventMaskBit(kCGEventOtherMouseUp)\
)

#define SCROLL_MASK (\
CGEventMaskBit(kCGEventScrollWheel)\
)

#define TABLET_MASK (\
CGEventMaskBit(kCGEventTabletProximity)\
)

#define KEYBOARD_MASK (\
CGEventMaskBit(kCGEventKeyDown)\
)

#define FLAGS_MASK (\
CGEventMaskBit(kCGEventFlagsChanged)\
)

typedef enum {
	DCTapActivityKeyboard,
	DCTapActivityScroll,
	DCTapActivityMovement,
	DCTapActivityButton,
	DCTapActivityGesture,
	DCTapActivityTabletLift,
	DCTapActivityModifierKey,
	DCTapActivityMax
} DCTapActivity;

@interface DCMouseTap : NSObject <DCActivation, DCMouseMonitoring, DCDragTypeSetting> {
	CFMachPortRef port;
	CFRunLoopSourceRef source;
	__unsafe_unretained id<DCMouseMonitoringDelegate> delegate;
@public
    // pid of the app that last moved the mouse
    uint64_t lastMovePid;
    
    // button detection
    // YES if any mouse button down, NO if all up
    BOOL buttonsClear;
    
    // event numbers
    short eventNumber;
    short eventNumberForButton[NUM_MOUSE_BUTTONS+1];
    
    // Where the mouse was last time it was moved or dragged
    CGPoint lastMoveLocation;
    NSTimeInterval lastMoveTime;
    
    // dwell detection
    NSTimeInterval dwellTime;
    CGFloat dwellRadius;
    CGPoint dwellCenter;
    NSTimer *timer;
    
    // move detection
    CGFloat moveRadius;
    BOOL enableMoveDetect;
    CGPoint moveCenter;
    
    // drag insertion
    CGEventType dragType;
    CGEventFlags dragFlags;
    
    // tablet proximity data
    BOOL tabletProximity;
    BOOL hasDwelledSincePenOffTablet;
    
    // ui snapshot data
    NSUInteger initialFingers;
    NSUInteger minFingers;
    NSUInteger maxFingers;
    pid_t initialActivePid;
    
    // activity notification
    BOOL activitySinceRest[DCTapActivityMax];
    
    // modifier tracking
    CGEventFlags previousModifiers;
    CGEventFlags waitingModifiers;
    
    NSTimer *bounceTimer;

}
- (NSTimeInterval)dwelledTime;
- (BOOL)mouseMovedWithinTimeInterval:(NSTimeInterval)interval;
- (void)startBounceTimer;
- (void)mouseDidMove;
- (void)enableTap:(BOOL)state;
@end

