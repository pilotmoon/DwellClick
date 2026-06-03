// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMEventUtils.h"

const CGEventFlags NMAllFourModifierFlags=kCGEventFlagMaskCommand|kCGEventFlagMaskAlternate|kCGEventFlagMaskControl|kCGEventFlagMaskShift;
const CGEventMask NMAllKeyEventsMask=NSKeyDownMask|NSKeyUpMask|NSFlagsChangedMask;

NSString *NMStringFromEventType(NSEventType type)
{
	NSString *result=@"unk";
#define CASE(type) \
case type: \
result=@#type; \
break;
    
	switch (type) {
            CASE(NSLeftMouseDown)
            CASE(NSLeftMouseUp)
            CASE(NSRightMouseDown)
            CASE(NSRightMouseUp)
            CASE(NSMouseMoved)
            CASE(NSLeftMouseDragged)
            CASE(NSRightMouseDragged)
            CASE(NSMouseEntered)
            CASE(NSMouseExited)
            CASE(NSKeyDown)
            CASE(NSKeyUp)
            CASE(NSFlagsChanged)
            CASE(NSAppKitDefined)
            CASE(NSSystemDefined)
            CASE(NSApplicationDefined)
            CASE(NSPeriodic)
            CASE(NSCursorUpdate)
            CASE(NSScrollWheel)
            CASE(NSTabletPoint)
            CASE(NSTabletProximity)
            CASE(NSOtherMouseDown)
            CASE(NSOtherMouseUp)
            CASE(NSOtherMouseDragged)
            CASE(NSEventTypeGesture)
            CASE(NSEventTypeMagnify)
            CASE(NSEventTypeSwipe)
            CASE(NSEventTypeRotate)
            CASE(NSEventTypeBeginGesture)
            CASE(NSEventTypeEndGesture)
		default:
			break;
	}
	return result;
}

// generate a 32-bit value that ought to be unique to this instance of this application
// (note top 32 bits of the 64 bit result are zero)
uint64_t NMInstanceSignatureValue(void)
{
    static uint64_t val=0;
    if (val==0) {
        const uint64_t sig=0x4e4d4e4d; // NMNM in hex
        const uint64_t pid=(uint64_t)getpid();
        val=(sig^pid)&0xFFFFFFFF;
    }
//    NMLogTemp(@"APP SIG 0x%016llx", val);
    return val;
}

BOOL NMCheckInstanceSignature(CGEventRef event)
{
    const uint64_t ud=CGEventGetIntegerValueField(event, kCGEventSourceUserData);
//    NMLogTemp(@"UD      0x%016x", ud);
    return ud==NMInstanceSignatureValue();
}

// this version seems to have broken in 10.11.4. TODO: investigate
//BOOL NMCheckEventSignature(CGEventRef event)
//{
//    pid_t pid=(pid_t)CGEventGetIntegerValueField(event, kCGEventSourceUnixProcessID);
//    return pid==getpid();
//}

CGEventFlags NMGetCurrentEventFlags(void)
{
	CGEventRef event=CGEventCreate(NULL);
	CGEventFlags eventFlags=CGEventGetFlags(event);
	CFRelease(event);
	return eventFlags;
}

static void _postFlagKeys(CGEventSourceRef source, CGEventFlags flags, bool keyDown)
{
    if (flags&NMAllFourModifierFlags) {
        void (^postKeyBlock)(CGEventFlags, CGKeyCode)=^(CGEventFlags keyFlag, CGKeyCode keyCode) {
            if (flags&keyFlag) {
                const CGEventRef flagKeyEvent = CGEventCreateKeyboardEvent(source, keyCode, keyDown);
                NMPostEvent(kCGAnnotatedSessionEventTap, flagKeyEvent);
                CFRelease(flagKeyEvent);
            }
        };
        postKeyBlock(kCGEventFlagMaskCommand, kVK_Command);
        postKeyBlock(kCGEventFlagMaskAlternate, kVK_Option);
        postKeyBlock(kCGEventFlagMaskControl, kVK_Control);
        postKeyBlock(kCGEventFlagMaskShift, kVK_Shift);
    }
}

void NMPostKeyWithFlags(CGKeyCode key, CGEventFlags flags)
{
    const NSTimeInterval kKeySleepTime=0.025;    
    const CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    
    // which flags are missing
    const CGEventFlags originalFlags=NMGetCurrentEventFlags();
    const CGEventFlags missingFlags=flags&~originalFlags;
    
    // also post the key down messages, some things seem to need to see this too
    _postFlagKeys(source, missingFlags, TRUE);
    
     [NSThread sleepForTimeInterval:kKeySleepTime];

    // key down
	const CGEventRef keyDown = CGEventCreateKeyboardEvent(source, key, TRUE);
	CGEventSetFlags(keyDown, flags);
	NMPostEvent(kCGAnnotatedSessionEventTap, keyDown);
	CFRelease(keyDown);
    

    [NSThread sleepForTimeInterval:kKeySleepTime];
    
    // key up
    const CGEventRef keyUp = CGEventCreateKeyboardEvent(source, key, FALSE);
	NMPostEvent(kCGAnnotatedSessionEventTap, keyUp);
	CFRelease(keyUp);	

     [NSThread sleepForTimeInterval:kKeySleepTime];

    _postFlagKeys(source, missingFlags, FALSE);

	CFRelease(source);	
}

void NMPostCommandAndKey(CGKeyCode key)
{
    NMPostKeyWithFlags(key, kCGEventFlagMaskCommand);
}

void NMPostKey(CGKeyCode key)
{
    NMPostKeyWithFlags(key, 0);
}

// single wrapper for all CGEventPost calls
void NMPostEvent(CGEventTapLocation loc, CGEventRef event)
{
    CGEventSetIntegerValueField(event, kCGEventSourceUserData, NMInstanceSignatureValue());
    CGEventPost(loc, event);
}

