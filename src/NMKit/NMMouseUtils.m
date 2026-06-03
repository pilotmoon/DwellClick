// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMMouseUtils.h"
#import "NMEventUtils.h"

static BOOL _override;
static CGPoint _overrideFlipped;
static CGPoint _overrideUnflipped;

void NMSetOverridePoint(CGPoint flipped, CGPoint unflipped)
{
	_overrideFlipped=flipped;
	_overrideUnflipped=unflipped;
}

void NMSetOverride(BOOL state)
{
	if (state&&!_override) {
		_overrideFlipped=NMCurrentFlippedMouseLocation();
		_overrideUnflipped=NMCurrentUnflippedMouseLocation();
	}	
	else if (!state&&_override){
		NMPostMouseEvent(kCGEventMouseMoved, _overrideFlipped, 0);
	}
	_override=state;
}
BOOL NMOverride(void)
{
    return _override;
}

CGPoint NMCurrentFlippedMouseLocation(void)
{
	if (_override) {
		return _overrideFlipped;
	}
	else {
		CGEventRef event=CGEventCreate(NULL);
		CGPoint result=CGEventGetLocation(event);
		CFRelease(event);
		return result;		
	}
}

CGPoint NMCurrentUnflippedMouseLocation(void)
{
	if (_override) {
		return _overrideUnflipped;
	}
	else {
		CGEventRef event=CGEventCreate(NULL);
		CGPoint result=CGEventGetUnflippedLocation(event);
		CFRelease(event);
		return result;
	}
}

void NMPostMouseEvent(CGEventType type, CGPoint point, uint64_t clickState)
{
	NMPostMouseEventWithFlags(type, point, clickState, 0);
}

void NMPostMouseEventWithFlags(CGEventType type, CGPoint point, uint64_t clickState, CGEventFlags flags)
{
	CGEventSourceRef source=CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
	CGEventRef event=CGEventCreateMouseEvent(source, type, point, 0);	
	CGEventFlags currentFlags=CGEventGetFlags(event);
	CGEventSetFlags(event, flags | currentFlags);
	CGEventSetIntegerValueField(event, kCGMouseEventClickState, clickState);
	NMPostEvent(kCGSessionEventTap, event);
	CFRelease(event);
	CFRelease(source);
}