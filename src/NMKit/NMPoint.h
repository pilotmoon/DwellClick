// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>


@interface NMPoint : NSObject {
	NSPoint point;
}

+ (NMPoint *)currentUnflippedMouseLocation;
+ (NMPoint *)currentFlippedMouseLocation;
+ (NMPoint *)zeroPoint;
+ (NMPoint *)pointWithNSPoint:(NSPoint)nsPoint;
+ (NMPoint *)pointWithCGPoint:(CGPoint)cgPoint;
+ (NMPoint *)pointWithX:(CGFloat)x Y:(CGFloat)y;

- (id)initWithNSPoint:(NSPoint)nsPoint;
- (id)initWithCGPoint:(CGPoint)cgPoint;
- (id)initWithX:(CGFloat)x Y:(CGFloat)y;

- (NSPoint)nsPoint;
- (CGPoint)cgPoint;

- (CGFloat)x;
- (CGFloat)y;

- (NMPoint *)flip;

// distance is defined as actual distance (radius) here
- (BOOL)isWithinDistance:(CGFloat)distance
				 ofPoint:(NMPoint *)aPoint;

// distance defined as within a box; 0=exactly in corner pixel
- (BOOL)isWithinDistance:(CGFloat)distance
		  ofCornerOfRect:(NSRect)rect;

// angle to other point in radians
- (CGFloat)angleToPoint:(NMPoint *)otherPoint;
- (CGFloat)distanceToPoint:(NMPoint *)otherPoint;
- (CGFloat)directionChangeFromPoint:(NMPoint *)firstPoint toPoint:(NMPoint *)secondPoint;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;
- (NSString *)description;

@end
