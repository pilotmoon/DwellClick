// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMPoint.h"
#import "NMMouseUtils.h"
#import "NMGeometryUtils.h"

@implementation NMPoint

#pragma mark Class methods

// mouse location in appkit coordinates
+ (NMPoint *)currentUnflippedMouseLocation
{
	return [[NMPoint alloc] initWithCGPoint:NMCurrentUnflippedMouseLocation()];
}

// mouse location in quartz coordinates
+ (NMPoint *)currentFlippedMouseLocation
{
	return [[NMPoint alloc] initWithCGPoint:NMCurrentFlippedMouseLocation()];	
}

+ (NMPoint *)zeroPoint
{
	return [[NMPoint alloc] initWithNSPoint:NSZeroPoint];
}

+ (NMPoint *)pointWithNSPoint:(NSPoint)nsPoint
{
	return [[NMPoint alloc] initWithNSPoint:nsPoint];	

}

+ (NMPoint *)pointWithCGPoint:(CGPoint)cgPoint
{
	return [[NMPoint alloc] initWithCGPoint:cgPoint];	
	
}

+ (NMPoint *)pointWithX:(CGFloat)x Y:(CGFloat)y
{
	return [[NMPoint alloc] initWithX:x Y:y];
}


#pragma mark Initializers

- (id)initWithNSPoint:(NSPoint)nsPoint
{
	point = nsPoint;
	return self;
}

- (id)initWithCGPoint:(CGPoint)cgPoint
{
	point = NSPointFromCGPoint(cgPoint);
	return self;
}

- (id)initWithX:(CGFloat)x Y:(CGFloat)y
{
	point.x = x;
	point.y = y;
	return self;
}


#pragma mark Point access

- (NSPoint)nsPoint
{
	return point;
}

- (CGPoint)cgPoint
{
	return NSPointToCGPoint(point);
}

#pragma mark X and Y Components

- (CGFloat)x
{
	return point.x;
}

- (CGFloat)y
{
	return point.y;
}

#pragma mark Flip method

- (NMPoint *)flip
{
	return [NMPoint pointWithX:[self x] Y:[(NSScreen *)[NSScreen screens][0] frame].size.height-[self y]];
}

#pragma mark Distance methods

- (BOOL)isWithinDistance:(CGFloat)distance
				 ofPoint:(NMPoint *)aPoint
{
	return NMPointsWithinDistance([self cgPoint], [aPoint cgPoint], distance);
}

- (BOOL)isWithinDistance:(CGFloat)distance
		  ofCornerOfRect:(NSRect)rect;
{
	return NMPointInCorner([self cgPoint], NSRectToCGRect(rect), distance);
}

#pragma mark Vector methods

- (CGFloat)angleToPoint:(NMPoint *)otherPoint
{
    return NMVectorDirection([self cgPoint], [otherPoint cgPoint]);
}

- (CGFloat)distanceToPoint:(NMPoint *)otherPoint
{
    return NMVectorLength([self cgPoint], [otherPoint cgPoint]);
}

- (CGFloat)directionChangeFromPoint:(NMPoint *)firstPoint toPoint:(NMPoint *)secondPoint
{
    // in degrees
    return 180.0*NMThreePointAngle([self cgPoint], [firstPoint cgPoint], [secondPoint cgPoint]) * M_1_PI;
}


#pragma mark NSObject methods

- (BOOL)isEqual:(id)object
{
	if (self == object) {
		return YES;
	}
	if (![object isKindOfClass:[NMPoint class]]) {
		return NO;
	}
	return [self x] == [object x] && [self y] == [object y];
}

- (NSUInteger)hash
{
	return [self x] * 11 + [self y] * 13;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"(%f, %f)", [self x], [self y]];
}

@end