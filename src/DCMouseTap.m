// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCMouseTap.h"
#import "DCUtils.h"
#import "NMKit/NMMouseUtils.h"
#import "NMKit/NMEventUtils.h"
#import "NMKit/NMPoint.h"
#import "DCEngine.h"
#import "DCEngine+Gubbins.h"
#import "DCTouchMonitor.h"
#import "DCConstants.h"
#import "NMKit/NMConfigUtils.h"
#import "NMKit/NMBlockUtils.h"
#import "NMKit/NMCUtils.h"
#import "NMKit/NMAppUtils.h"
#import "NMKit/NMGeometryUtils.h"

BOOL DCFlagTabletWasUsed=NO;

// this flag make dwellclick suppress all external flag change events, and only
// produce its own. This was added to get around a bug in the ap 'iTracker'.
static BOOL _suppressExternalModifiers=NO;

static void _clearActivityFlags(BOOL array[DCTapActivityMax])
{
	NM_memset(array,0,sizeof(BOOL)*DCTapActivityMax);
}								

static void _notifyActivity(DCMouseTap *td, DCTapActivity activity)
{
	if (!td->activitySinceRest[activity]) {
		td->activitySinceRest[activity]=YES;
		[[DCEngine sharedInstance] activityDetectedSinceRest:activity];
	}
	if (activity==DCTapActivityKeyboard||activity==DCTapActivityButton) {
		[[DCEngine sharedInstance] activityDetected:activity];
	}
}

/* This is called every time the mouse does anything.
  It has to be efficient. */
static CGEventRef eventTapCallback (CGEventTapProxy proxy,
							 CGEventType type,
							 CGEventRef event,
							 void * refcon)
{
	DCMouseTap * const td=(__bridge DCMouseTap *)refcon;
	NSCAssert(td != nil, @"bad tap");
	BOOL suppressEvent=NO;
    BOOL noAddFlags=NO;
    const CGEventFlags initialFlags=td->dragFlags;

    
    
	// the current event mask bit
	const CGEventMask bit = CGEventMaskBit(type);
    // the current event flags
    const CGEventFlags flags = _suppressExternalModifiers?CGEventGetFlags(event)&(~NMAllFourModifierFlags):CGEventGetFlags(event);
    
    //log(@"event %@ (%@)", NMStringFromEventType(type), @(type));
    
	// a movin' or a clickin'
	if (bit&(MOVE_MASK|DRAG_MASK|UP_MASK|DOWN_MASK))
	{
        // is it our event
        const BOOL isOurEvent=NMCheckInstanceSignature(event);

		// get location
		const CGPoint location=CGEventGetLocation(event);
		
		if (NMOverride()) {
			suppressEvent=[[DCEngine sharedInstance].popupsController mouseEventDuringOverride:event type:type location:location];
		}
		
		// has it actually moved?
		BOOL moved=!CGPointEqualToPoint(location,td->lastMoveLocation);

		// if mouse was moved
		if (bit&(MOVE_MASK|DRAG_MASK))
		{	
			// set event number to most recently used event number
			CGEventSetIntegerValueField(event, kCGMouseEventNumber, td->eventNumber);

			// record last move location and pid
			td->lastMoveLocation=location;
			td->lastMovePid=CGEventGetIntegerValueField(event, kCGEventSourceUnixProcessID);
			if (moved && !isOurEvent) {
				td->lastMoveTime=CFAbsoluteTimeGetCurrent();
			}
            
			if((0!=td->dragType)&&!isOurEvent) // force dragging
			{ 
				// set the drag type
				CGEventSetType(event, td->dragType);
				// set other fields
				CGEventSetIntegerValueField(event, kCGMouseEventClickState, 1);
				CGEventSetDoubleValueField(event, kCGMouseEventPressure, 1.0);
			}
			
			// dwell detection
			CGFloat jitterRadius=td->dwellRadius;
			if (td->tabletProximity) {
				jitterRadius+=3;
			}
			if (td->dwellTime<0.185) {
				jitterRadius=0;
			}
			if (!NMPointsWithinDistance(location, td->dwellCenter, jitterRadius))
			{
				if ([td->timer isValid]) 
				{
					// it has moved, restart the timer
					td->dwellCenter=location;
					td->initialActivePid=NMActiveApplicationPID();
					_clearActivityFlags(td->activitySinceRest);
					*DCAnimationPosition=0;
					*DCAnimationHide=NO;
					[td->timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:td->dwellTime]];
				}
			}
			
			// move detection
			if (td->enableMoveDetect&&!isOurEvent)
			{
				if(!NMPointsWithinDistance(location, td->moveCenter, td->moveRadius))
				{
					td->enableMoveDetect = NO;
					td->initialFingers=td->minFingers=td->maxFingers=DCTouchMonitorFingers;
					_notifyActivity(td, DCTapActivityMovement);
					[td mouseDidMove];
				}
			}
		}
		else // up mask or down mask
		{
			td->moveCenter=location;
			uint64_t prevEventNumber=0;
			
			// mouse button number
			uint64_t buttonNumber=CGEventGetIntegerValueField(event, kCGMouseEventButtonNumber);
			if (buttonNumber>NUM_MOUSE_BUTTONS) // this should never happen, but id it does it's safe
			{
				buttonNumber=NUM_MOUSE_BUTTONS;
			}
	
			// new event number if it's a down
			if (bit&DOWN_MASK)
			{
				prevEventNumber=td->eventNumberForButton[buttonNumber];
				td->eventNumberForButton[buttonNumber]=++td->eventNumber;					
			}
			// set the event number for this button
			CGEventSetIntegerValueField(event, kCGMouseEventNumber, td->eventNumberForButton[buttonNumber]);					
		
			if (bit&DOWN_MASK)
			{
				td->waitingModifiers=0;
			}
			
			// leave now if it's our own click
			if(isOurEvent)
			{ 
				if (!suppressEvent&&(bit&UP_MASK)) {
                    [[DCEngine sharedInstance] incrementDwellClickCount];	
				}
				goto tap_end;
			}
			
			// further processinf
			if (bit&DOWN_MASK)
			{
				_notifyActivity(td, DCTapActivityButton);
				
				// special: if mouse clicked while dragging
				if(0 != td->dragType)
				{ 
					if ((td->dragType==kCGEventLeftMouseDragged&&type==kCGEventLeftMouseDown) ||
						(td->dragType==kCGEventRightMouseDragged&&type==kCGEventRightMouseDown))
					{
						// restore the event number for the button up, since we're not sending this down
						td->eventNumber--;
						td->eventNumberForButton[buttonNumber]=prevEventNumber;
						[[DCEngine sharedInstance] draggingSameButtonDown];
						suppressEvent=YES;;
					}
					else
					{
						[[DCEngine sharedInstance] draggingOtherButtonDown];
					}
				}
			}
			else // up mask
			{
				[[DCEngine sharedInstance] userPerformedManualClick];
			}	
		}
		
		// fake drag was introduced because Smart Scroll was sending drag events and confusing us
		const BOOL fakeDrag=(!moved)&&(bit&DRAG_MASK);
		const BOOL buttonsClear=(bit&(MOVE_MASK|UP_MASK))||fakeDrag;
		
		// send notification if the button state has changed
		if (td->buttonsClear != buttonsClear)
		{
			buttonsClear ? [[td delegate] mouseButtonWasReleased] : [[td delegate] mouseButtonWasPressed];
			td->buttonsClear=buttonsClear;
		}
	} 
	else if (bit&SCROLL_MASK) // scroll wheel was used
	{ 
		_notifyActivity(td, DCTapActivityScroll);
	}
	else if (bit&TABLET_MASK) // tablet event
	{ 
		// is the pen next to the tablet?
		const int64_t prox=CGEventGetIntegerValueField(event, kCGTabletProximityEventEnterProximity);
		BOOL newValue=!(prox==0);
		if (td->tabletProximity && !newValue) {
			_notifyActivity(td, DCTapActivityTabletLift);
		}
		td->tabletProximity=newValue;
		if (td->tabletProximity)
		{
			DCFlagTabletWasUsed=YES;
			td->hasDwelledSincePenOffTablet=NO;
		}
	}
	else if (bit&NSEventMaskGesture) 
	{
		DCTouchMonitorHandleTappedEvent(event);
       
		if (DCTouchMonitorFingers>1) {
			_notifyActivity(td, DCTapActivityGesture);
		}
		if(DCTouchMonitorFingers>td->maxFingers)
		{
			td->maxFingers=DCTouchMonitorFingers;
		}
		if(DCTouchMonitorFingers<td->minFingers)
		{
			td->minFingers=DCTouchMonitorFingers;
		}
	}
	else if (bit&KEYBOARD_MASK)
	{
		td->waitingModifiers=0;
		const uint64_t keyCode=CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
		if (keyCode==53) { // escape key
			suppressEvent=[[DCEngine sharedInstance] escKeyPressed];
		}
		else {
			_notifyActivity(td, DCTapActivityKeyboard);
		}
        noAddFlags=YES;
	}
	else if (bit&FLAGS_MASK)
	{
		for(CGEventFlags ibit=kCGEventFlagMaskShift; ibit<=kCGEventFlagMaskSecondaryFn; ibit<<=1) // this range is all we need
		{
			const BOOL now=!!(flags&ibit);
			const BOOL previous=!!(td->previousModifiers&ibit);
			if (now!=previous) {
			   if (now) {
				   suppressEvent=[[DCEngine sharedInstance] modifierButtonDown:ibit];
				   [td startBounceTimer];
				   td->waitingModifiers|=ibit;
			   }
			   else
			   {
				   if (td->waitingModifiers&ibit) {
					   suppressEvent=[[DCEngine sharedInstance] modifierButtonPressed:ibit];
				   }
				   else {
					   suppressEvent=[[DCEngine sharedInstance] modifierButtonUp:ibit];
				   }
			   }
			}
		}
		td->previousModifiers=flags;
	}
	else // something else, probably error
	{
		NMLogInfo(@"tap event: %d **************", type);
		if(type==kCGEventTapDisabledByTimeout) // (-2) this can happen sometimes (why? dunno...)
		{ 
			[td enableTap:TRUE]; // just re-enable it
		}
	}

tap_end:
    // set flags for this event
    if(!noAddFlags) {
        CGEventSetFlags(event, (flags | td->dragFlags));
    }
    
    // send modifiers changed first if flags have changed
    const CGEventFlags offFlags=(initialFlags^(td->dragFlags))&initialFlags;
    if (offFlags!=0) {
        CGEventRef clearEvent=CGEventCreate(NULL);
        CGEventSetFlags(clearEvent, flags&(~offFlags));
        CGEventSetType(clearEvent, kCGEventFlagsChanged);
        CGEventTapPostEvent(proxy, clearEvent);
        CFRelease(clearEvent);
        //Log(@"posted clear flags in tap");
        //Log(@"FLAGS 0x%016llx init 0x%016llx new 0x%016llx off 0x%016llx", flags, initialFlags, td->dragFlags, offFlags);
    }
    
    
    // NMLogInfo(@"event has flags 0x%016llx : 0x%016llx", CGEventGetFlags(event), td->dragFlags);
	// returning the event passes it down to the apps
    
	return suppressEvent ? NULL : event;
}

@implementation DCMouseTap
@synthesize delegate;

+ (void)initialize
{
    if (self==[DCMouseTap class]) {
        _suppressExternalModifiers=[[NSUserDefaults standardUserDefaults] boolForKey:@"SuppressExternalModifiers"];
    }
}


- (id)init
{
	if (!(self=[super init])) return nil;
	
	return self;
}

- (void)dealloc
{
	[self stop];
}

#pragma mark Special tap enable

- (void)enableTap:(BOOL)state
{
	CGEventTapEnable(port, state);
}

#pragma mark Accessors

- (void)setDwellTime:(NSTimeInterval)aDwellTime
{
	[self willChangeValueForKey:@"dwellTime"];
	dwellTime = aDwellTime;
	[self didChangeValueForKey:@"dwellTime"];
}

- (NSTimeInterval)dwellTime
{
	return dwellTime;
}

- (void)setMoveRadius:(CGFloat)aMoveRadius
{
	[self willChangeValueForKey:@"moveRadius"];
	moveRadius = aMoveRadius;
	[self didChangeValueForKey:@"moveRadius"];
}

- (CGFloat)moveRadius
{
	return moveRadius;
}

- (void)setDwellRadius:(CGFloat)aDwellRadius
{
	[self willChangeValueForKey:@"dwellRadius"];
	dwellRadius = aDwellRadius;
	[self didChangeValueForKey:@"dwellRadius"];
}

- (CGFloat)dwellRadius
{
	return dwellRadius;
}

- (void)setDragType:(CGEventType)aDragType
{
	if (!(0==aDragType||kCGEventLeftMouseDragged==aDragType||kCGEventRightMouseDragged==aDragType)) {
		[NSException raise:NSInvalidArgumentException format:@"bad drag type: %d", aDragType];
	}
	[self willChangeValueForKey:@"dragType"];
	dragType=aDragType;
	[self didChangeValueForKey:@"dragType"];
}

- (CGEventType)dragType
{
	return dragType;
}

- (void)setDragFlags:(CGEventFlags)aDragFlags
{
	[self willChangeValueForKey:@"dragFlags"];
	dragFlags=aDragFlags;
	[self didChangeValueForKey:@"dragFlags"];
}

- (CGEventFlags)dragFlags
{
	return dragFlags;
}

#pragma mark Activation

- (void)start
{
	NMLogInfo(@"tap start called");
	if(![self isActive]) {
		buttonsClear=YES;
		lastMoveLocation=CGPointMake(0,0);
		lastMoveTime=0;
		dwellCenter=CGPointMake(0,0);
		hasDwelledSincePenOffTablet=YES;
		eventNumber=INITIAL_EVENT_NUMBER;
		previousModifiers=0;
		waitingModifiers=0;
		NM_memset(eventNumberForButton, 0, sizeof(eventNumberForButton));

		[self willChangeValueForKey:@"active"];
		
		CGEventMask mask=MOVE_MASK | DRAG_MASK | DOWN_MASK | UP_MASK | SCROLL_MASK | TABLET_MASK | KEYBOARD_MASK | FLAGS_MASK | NSEventMaskGesture;

        
        // create mach port
        port = (CFMachPortRef)CGEventTapCreate(kCGSessionEventTap,
                                                kCGHeadInsertEventTap,
                                                kCGEventTapOptionDefault,
                                                mask,
                                                eventTapCallback,
                                                (__bridge void *)(self));
        
        // create source and add to tun loop
        if (port) {
            source = (CFRunLoopSourceRef)CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0);
            
            if (source) {
                CFRunLoopAddSource(CFRunLoopGetMain(), source, kCFRunLoopCommonModes);
            }
            else {
                CFMachPortInvalidate(port);
                CFRelease(port);
                port=nil;
            }
        }
		
		[self didChangeValueForKey:@"active"];
	}
}

- (void)stop
{
	if ([self isActive]) {
		[self willChangeValueForKey:@"active"];
        
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, kCFRunLoopCommonModes);
        CFMachPortInvalidate(port);
        CFRelease(source);
        CFRelease(port);
        source=nil;
        port=nil;
        
		[self stopMoveDetect];
		[self stopDwellDetect];
		[self didChangeValueForKey:@"active"];		
	}
}

- (void)setActive:(BOOL)state
{
	state?[self start]:[self stop];
}

- (BOOL)isActive
{
	return source&&port;
}

#pragma mark Dwell Detection Filtering

- (void)mouseDidMove
{
	[[self delegate] mouseDidMove];
	[[DCEngine sharedInstance] moveDetected];
}

- (void)mouseDidDwell
{
	[[DCEngine sharedInstance] dwellDetected];
	
	// which selector to call
	SEL sel=@selector(mouseDidDwell);
			
	// tablet proximity stuff
	if(!tabletProximity) {
		if (!hasDwelledSincePenOffTablet) sel=@selector(mouseDidDwellIgnore);
		hasDwelledSincePenOffTablet=YES;
	}
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[((NSObject *)[self delegate]) performSelector:sel];
#pragma clang diagnostic pop
}

#pragma mark Control

- (void)startDwellDetect
{
	[[DCEngine sharedInstance] restDetected];
	timer = [NSTimer timerWithTimeInterval:[self dwellTime]
									target:self
								  selector:@selector(mouseDidDwell)
								  userInfo:nil
								   repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];	
}

- (void)stopDwellDetect
{
	[timer invalidate];
}

- (void)startMoveDetectWithLocation:(NMPoint *)point;
{
	enableMoveDetect = YES;
	moveCenter = [point cgPoint];
}

- (void)startMoveDetect
{
	[self startMoveDetectWithLocation:[NMPoint currentFlippedMouseLocation]];
}

- (void)stopMoveDetect
{
	enableMoveDetect = NO;
}

- (void)bounceTime
{
	waitingModifiers=0;
	bounceTimer=nil;
}

#define BOUNCE_TIME 0.4
- (void)startBounceTimer
{
	if (!bounceTimer) {
		bounceTimer=[NSTimer scheduledTimerWithTimeInterval:BOUNCE_TIME target:self selector:@selector(bounceTime) userInfo:0 repeats:NO];		
	}
	else {
		[bounceTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:BOUNCE_TIME]];
	}
}

- (NSTimeInterval)dwelledTime
{
	return dwellTime-([timer isValid]?[[timer fireDate] timeIntervalSinceNow]:0);
}

- (BOOL)mouseMovedWithinTimeInterval:(NSTimeInterval)interval
{
	return lastMoveTime>0 && CFAbsoluteTimeGetCurrent()-lastMoveTime<=interval;
}

@end
