// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#include <ApplicationServices/ApplicationServices.h>

void NMSetOverridePoint(CGPoint flipped, CGPoint unflipped);
void NMSetOverride(BOOL state);
BOOL NMOverride(void);

// Location of mouse in "flipped" coordinates as used by the Quartz subsystem.
// Height is inverted from w.r.t. AppKit coordinates.
CGPoint NMCurrentFlippedMouseLocation(void);

// AppKit-compatible location equivalent to [NSEvent mouseLocation]
CGPoint NMCurrentUnflippedMouseLocation(void);

void NMPostMouseEvent(CGEventType type, CGPoint point, uint64_t clickState);

void NMPostMouseEventWithFlags(CGEventType type, CGPoint point, uint64_t clickState, CGEventFlags flags);
