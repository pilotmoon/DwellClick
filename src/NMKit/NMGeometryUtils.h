// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

Boolean NMPointsWithinDistance(NSPoint p, NSPoint q, CGFloat d);

Boolean NMPointInCorner(NSPoint p, CGRect r, CGFloat d);

NSPoint NMPointDifference(NSPoint p, NSPoint q);
NSPoint NMPointSum(NSPoint p, NSPoint q);

CGFloat NMVectorDirection(NSPoint p, NSPoint q);
CGFloat NMVectorLength(NSPoint p, NSPoint q);
CGFloat NMThreePointAngle(NSPoint p, NSPoint q, NSPoint r);
CGFloat NMThreePointAngleAbs(NSPoint p, NSPoint q, NSPoint r);

CGFloat NMFlipY(CGFloat y);

NSPoint NMFlipPoint(NSPoint point);

NSRect NMFlipRect(NSRect rect);

NSRect NMOffsetRect(NSRect rect, NSPoint offset);

NSPoint NMPointForCenteredBoxInBox(NSSize box, NSSize container);

NSRect NMRectForCenteredBoxInBox(NSSize box, NSSize container);

NSRect NMRectForCenteredBoxInFrame(NSSize box, NSRect container);

NSPoint NMPointRound(NSPoint point);
NSSize NMSizeRound(NSSize size);
NSRect NMRectRound(NSRect rect);

BOOL NMPointInView(NSPoint point, NSView *view);

BOOL NMMouseInView(NSView *view);

NSSize NMSwapSize(NSSize size);

NSSize NMScaleSize(NSSize size, CGFloat factor);

NSRect NMRectFromSize(NSSize size);

BOOL NMCircleIntersectsLine (NSPoint center, CGFloat radius, NSPoint point1, NSPoint point2, NSPoint *intersect1, NSPoint *intersect2);