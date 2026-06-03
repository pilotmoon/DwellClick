// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "Carbon/Carbon.h" // useful for CGKeyCodes e.g. kVK_ANSI_C

extern const CGEventFlags NMAllFourModifierFlags;
extern const CGEventMask NMAllKeyEventsMask;

NSString *NMStringFromEventType(NSEventType type);

// generate a 32-bit value that ought to be unique to this instance of this application
// (note top 32 bits of the 64 bit result are zero)
uint64_t NMInstanceSignatureValue(void);
BOOL NMCheckInstanceSignature(CGEventRef event);
//BOOL NMCheckEventSignature(CGEventRef event);

CGEventFlags NMGetCurrentEventFlags(void);

void NMPostKeyWithFlags(CGKeyCode key, CGEventFlags flags);
void NMPostCommandAndKey(CGKeyCode key);
void NMPostKey(CGKeyCode key);

void NMPostEvent(CGEventTapLocation loc, CGEventRef event);