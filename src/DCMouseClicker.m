// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCMouseClicker.h"
#import "NMKit/NMMouseUtils.h"
#import "NMKit/NMPoint.h"
#import "DCClickEvent.h"
#import "DCFlagGroup.h"
#import "DCMouseTap.h"
#import "DCEngine.h"
#import "DCConstants.h"
#import "DCUtils.h"
#import "NMKit/NMBlockUtils.h"

static NSOperationQueue *_opQueue;
static const CGFloat _quickDragDistance=10;
static const NSTimeInterval _quickDragIntervalMin=0.10;
static const NSTimeInterval _quickDragIntervalMax=0.30;
static const NSTimeInterval _normalInterval=0.04;

static NSTimeInterval _quickDragInterval(void)
{
	NSTimeInterval result=_quickDragIntervalMin+((_quickDragIntervalMax-_quickDragIntervalMin)*[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsQuickDragInterval]);
	//NMLogInfo(@"qdi=%f", result);
	return result;
}

static void _scheduleOp(NSOperation *op)
{	
	[_opQueue addOperation:op];
}

static void _setupOpQueue()
{
	if(!_opQueue) {
		_opQueue=[[NSOperationQueue alloc] init];
		[_opQueue setMaxConcurrentOperationCount:1];	
	}
}

@implementation DCMouseClicker

#pragma mark Setting up

+ (id)leftClickerWithModifierController:(DCFlagGroup *)modifierController
									tap:(DCMouseTap *)aTap
{
	return [[DCMouseClicker alloc] initWithDownType:kCGEventLeftMouseDown
											 upType:kCGEventLeftMouseUp
										   dragType:kCGEventLeftMouseDragged
										 eventFlags:0
								 modifierController:modifierController
												tap:aTap];
}

+ (id)rightClickerWithModifierController:(DCFlagGroup *)modifierController
									 tap:(DCMouseTap *)aTap
{
	return [[DCMouseClicker alloc] initWithDownType:kCGEventRightMouseDown
											 upType:kCGEventRightMouseUp
										   dragType:kCGEventRightMouseDragged
										 eventFlags:0
								 modifierController:modifierController
												tap:aTap];
}

+ (id)controlClickerWithModifierController:(DCFlagGroup *)modifierController
                                       tap:(DCMouseTap *)aTap
{
	return [[DCMouseClicker alloc] initWithDownType:kCGEventLeftMouseDown
											 upType:kCGEventLeftMouseUp
										   dragType:kCGEventLeftMouseDragged
										 eventFlags:kCGEventFlagMaskControl
								 modifierController:modifierController
												tap:aTap];
}

+ (id)optionClickerWithModifierController:(DCFlagGroup *)modifierController
                                      tap:(DCMouseTap *)aTap
{
	return [[DCMouseClicker alloc] initWithDownType:kCGEventLeftMouseDown
											 upType:kCGEventLeftMouseUp
										   dragType:kCGEventLeftMouseDragged
										 eventFlags:kCGEventFlagMaskAlternate
								 modifierController:modifierController
												tap:aTap];
}

+ (id)commandClickerWithModifierController:(DCFlagGroup *)modifierController
                                       tap:(DCMouseTap *)aTap
{
	return [[DCMouseClicker alloc] initWithDownType:kCGEventLeftMouseDown
											 upType:kCGEventLeftMouseUp
										   dragType:kCGEventLeftMouseDragged
										 eventFlags:kCGEventFlagMaskCommand
								 modifierController:modifierController
												tap:aTap];
}

+ (id)shiftClickerWithModifierController:(DCFlagGroup *)modifierController
									 tap:(DCMouseTap *)aTap
{
	return [[DCMouseClicker alloc] initWithDownType:kCGEventLeftMouseDown
											 upType:kCGEventLeftMouseUp
										   dragType:kCGEventLeftMouseDragged
										 eventFlags:kCGEventFlagMaskShift
								 modifierController:modifierController
												tap:aTap];
}

// designated initializer
- (id)initWithDownType:(CGEventType)aDownType
				upType:(CGEventType)anUpType
			  dragType:(CGEventType)aDragType
			eventFlags:(CGEventFlags)aEventFlags
	modifierController:(DCFlagGroup *)aModifierController
				   tap:(DCMouseTap *)aTap
{
	downType=aDownType;
	upType=anUpType;
	dragType=aDragType;
	eventFlags=aEventFlags;
	modifierController=aModifierController;
	tap=aTap;
	_setupOpQueue();
	return self;
}

#pragma mark Private Click Methods

- (void)doClickWithEvent:(DCClickEvent *)event
{
	CGPoint p = [event.uiState.mouseFlippedLocation cgPoint];
	CGEventFlags flags = modifierController.flags;
	
	// this will be the finishing code at the end
	NMBasicBlock finish=^{
		NMPostMouseEventWithFlags(upType, p, 1, eventFlags|flags);
		[NSThread sleepForTimeInterval:_normalInterval];	
		[event performSelectorOnMainThread:@selector(markAsComplete) withObject:nil waitUntilDone:YES];	
	};

	// post the mouse down
	NMPostMouseEventWithFlags(downType, p, 1, eventFlags|flags);

	// can we quick drag?
    BOOL canQuickDrag=[[DCEngine sharedInstance].intel canQuickDragWithEvent:event];
	if (!canQuickDrag)
	{
		// no, just wait a normal delay and finish
		[NSThread sleepForTimeInterval:_normalInterval];
		finish();
	}
	else // yesy! do crazy quick drag stuff.
	{
		tap.dragType=dragType;
		tap.dragFlags=eventFlags|modifierController.flags;
		[NSThread sleepForTimeInterval:_quickDragInterval()];
		// has it been swiped
		NMPoint *newPoint=[NMPoint currentFlippedMouseLocation];
		if (![newPoint isWithinDistance:_quickDragDistance ofPoint:event.uiState.mouseFlippedLocation])
		{
			if (tap.dragType==0) { // this would be set in DCEngine due to button down
				NMLogInfo(@"Quick drag cancelled by button press");
			}
			else {
				[[DCEngine sharedInstance] performSelectorOnMainThread:@selector(didQuickDragWithEvent:) withObject:event waitUntilDone:NO];
				return;
			}
		}
		tap.dragType=0;
		finish();
	}
	
}

- (void)doDoubleClickWithEvent:(DCClickEvent *)event
{
	CGPoint p = [event.uiState.mouseFlippedLocation cgPoint];
	CGEventFlags flags = modifierController.flags;
	NMPostMouseEventWithFlags(downType, p, 1, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	NMPostMouseEventWithFlags(upType, p, 1, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	NMPostMouseEventWithFlags(downType, p, 2, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	NMPostMouseEventWithFlags(upType, p, 2, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	[event performSelectorOnMainThread:@selector(markAsComplete) withObject:nil waitUntilDone:YES];
}


- (void)doTripleClickWithEvent:(DCClickEvent *)event
{
	CGPoint p = [event.uiState.mouseFlippedLocation cgPoint];
	CGEventFlags flags = modifierController.flags;
	NMPostMouseEventWithFlags(downType, p, 1, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	NMPostMouseEventWithFlags(upType, p, 1, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	NMPostMouseEventWithFlags(downType, p, 2, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	NMPostMouseEventWithFlags(upType, p, 2, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	NMPostMouseEventWithFlags(downType, p, 3, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	NMPostMouseEventWithFlags(upType, p, 3, eventFlags|flags);
	[NSThread sleepForTimeInterval:_normalInterval];
	[event performSelectorOnMainThread:@selector(markAsComplete) withObject:nil waitUntilDone:YES];
}

- (void)doDragBeginWithEvent:(DCClickEvent *)event
{
	tap.dragType=dragType;
	modifierController.flags|=eventFlags;
	NMPostMouseEventWithFlags(downType, [event.uiState.mouseFlippedLocation cgPoint], 1, modifierController.flags);
	[NSThread sleepForTimeInterval:_normalInterval];
}

- (void)doDragEndWithEvent:(DCClickEvent *)event
{
	NMPostMouseEventWithFlags(upType, [[event.uiState mouseFlippedLocation] cgPoint], 0, modifierController.flags);
	tap.dragType=0;
	[NSThread sleepForTimeInterval:_normalInterval];
	[event performSelectorOnMainThread:@selector(markAsComplete) withObject:nil waitUntilDone:YES];
}

#pragma mark public methods

- (void)clickWithEvent:(DCClickEvent *)event
{
	_scheduleOp([[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doClickWithEvent:) object:event]);
}

- (void)doubleClickWithEvent:(DCClickEvent *)event
{
	_scheduleOp([[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doDoubleClickWithEvent:) object:event]);
}

- (void)tripleClickWithEvent:(DCClickEvent *)event
{
	_scheduleOp([[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doTripleClickWithEvent:) object:event]);
}

- (void)dragBeginWithEvent:(DCClickEvent *)event
{
	_scheduleOp([[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doDragBeginWithEvent:) object:event]);
}

- (void)dragEndWithEvent:(DCClickEvent *)event
{
	_scheduleOp([[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doDragEndWithEvent:) object:event]);
}

@end
