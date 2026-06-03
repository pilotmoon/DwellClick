// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

// 10.6 stuff for touches

#define NSEventTypeGesture 29
#define NSEventMaskGesture (1<<NSEventTypeGesture)

enum {
	NSTouchPhaseBegan           = 1 << 0,
	NSTouchPhaseMoved           = 1 << 1,
	NSTouchPhaseStationary      = 1 << 2,
	NSTouchPhaseEnded           = 1 << 3,
	NSTouchPhaseCancelled       = 1 << 4,
	NSTouchPhaseTouching = NSTouchPhaseBegan | NSTouchPhaseMoved | NSTouchPhaseStationary,
	NSTouchPhaseAny             = NSUIntegerMax
};
typedef NSUInteger NSTouchPhase;

@interface NSEvent (Touches)
- (NSSet *)touchesMatchingPhase:(NSTouchPhase)phase inView:(NSView *)view;
@end