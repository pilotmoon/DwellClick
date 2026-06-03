// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMGeometryUtils.h"
#import <math.h>

Boolean NMPointsWithinDistance(NSPoint p, NSPoint q, CGFloat d)
{
    if (d<0) {
        return NO;
    }
	return (p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y) <= d * d;	
}

Boolean NMPointInCorner(NSPoint p, CGRect r, CGFloat d)
{
	CGFloat xmin = r.origin.x + d;
	CGFloat xmax = r.origin.x + r.size.width - 1 - d;
	CGFloat ymin = r.origin.y + d;
	CGFloat ymax = r.origin.y + r.size.height - 1 - d;
	return 	CGRectContainsPoint(r, p)
	&& (p.x <= xmin || p.x >= xmax)
	&& (p.y <= ymin || p.y >= ymax);
}

// difference q-p
NSPoint NMPointDifference(NSPoint p, NSPoint q)
{
    return NSMakePoint(q.x-p.x, q.y-p.y);
}

// sum p+q
NSPoint NMPointSum(NSPoint p, NSPoint q)
{
    return NSMakePoint(q.x+p.x, q.y+p.y);
}

// direction in radians of the vector p->q
CGFloat NMVectorDirection(NSPoint p, NSPoint q)
{
    return atan2(q.y-p.y, q.x-p.x );
}

// length of the vector p->q	
CGFloat NMVectorLength(NSPoint p, NSPoint q)
{
    return hypot(q.y-p.y, q.x-p.x);
}

// change in angle between p->q and q->r
// answer is always in range (-pi, pi]
CGFloat NMThreePointAngle(NSPoint p, NSPoint q, NSPoint r)
{
    const CGFloat diff=NMVectorDirection(q, r)-NMVectorDirection(p, q);
    if (diff>M_PI) {
        return 2*M_PI-diff;
    }
    else if (diff<-M_PI) {
        return -2*M_PI-diff;
    }
    else if (diff==-M_PI) {
        return M_PI;
    }
    else {
        return diff;
    }
}

// size of the angle between p->q and q->r
// answer is always in range [0, pi]
CGFloat NMThreePointAngleAbs(NSPoint p, NSPoint q, NSPoint r)
{
    const CGFloat diffabs=fabs(NMVectorDirection(q, r)-NMVectorDirection(p, q));
    return diffabs>M_PI?2*M_PI-diffabs:diffabs;
}

CGFloat NMFlipY(CGFloat y)
{
	return [(NSScreen *)[NSScreen screens][0] frame].size.height-y;
}

NSPoint NMFlipPoint(NSPoint point)
{
    point.y=NMFlipY(point.y);
    return point;
}

NSRect NMFlipRect(NSRect rect)
{
	rect.origin.y=NMFlipY(rect.origin.y+rect.size.height);	
	return rect;
}

NSRect NMOffsetRect(NSRect rect, NSPoint offset)
{
    rect.origin.x+=offset.x;
    rect.origin.y+=offset.y;
    return rect;
}

/* Return origin of inner rect centered in outer rect */
NSPoint NMPointForCenteredBoxInBox(NSSize box, NSSize container)
{
	return NMRectForCenteredBoxInBox(box, container).origin;
}

/* Return inner rect centered in outer rect */
NSRect NMRectForCenteredBoxInBox(NSSize box, NSSize container)
{
	return NMRectForCenteredBoxInFrame(box, NSMakeRect(0, 0, container.width, container.height));
}

/* Return inner rect centered in outer rect */
NSRect NMRectForCenteredBoxInFrame(NSSize box, NSRect container)
{
	return NSMakeRect((container.size.width-box.width)*0.5+container.origin.x, (container.size.height-box.height)*0.5+container.origin.y, box.width, box.height);
}

NSPoint NMPointRound(NSPoint point)
{
    return NSMakePoint(round(point.x), round(point.y));
}

NSSize NMSizeRound(NSSize size)
{
    return NSMakeSize(roundf(size.width), roundf(size.height));
}

NSRect NMRectRound(NSRect rect)
{
    NSRect result=NSZeroRect;
    result.size=NMSizeRound(rect.size);
    result.origin=NMPointRound(rect.origin);
    return result;
}

BOOL NMPointInView(NSPoint point, NSView *view)
{
    return NSPointInRect(point, [[view window] convertRectToScreen:[view frame]]);
}

BOOL NMMouseInView(NSView *view)
{
    return NMPointInView([NSEvent mouseLocation], view);
}

NSSize NMSwapSize(NSSize size)
{
    return NSMakeSize(size.height, size.width);
}

NSSize NMScaleSize(NSSize size, CGFloat factor)
{
    return NSMakeSize(size.width*factor, size.height*factor);
}

NSRect NMRectFromSize(NSSize size)
{
    return NSMakeRect(0, 0, size.width, size.height);
}

// if circle intersects line, return true and fill in the intersect points
// if no intersect, return false
// if tangent, retur true and both result points will be equal
// from http://mathworld.wolfram.com/Circle-LineIntersection.html
BOOL NMCircleIntersectsLine (NSPoint center, CGFloat radius, NSPoint point1, NSPoint point2, NSPoint *intersect1, NSPoint *intersect2)
{
    /* (x1, y1) and (x2, y2) are the line points relative to the centre */
    const CGFloat x1=point1.x-center.x;
    const CGFloat x2=point2.x-center.x;
    const CGFloat y1=point1.y-center.y;
    const CGFloat y2=point2.y-center.y;
    
    const CGFloat dx=x2-x1;
    const CGFloat dy=y2-y1;
    const CGFloat d2=dx*dx+dy*dy;
    
    const CGFloat r2=radius*radius;
    const CGFloat D=x1*y2-x2*y1;
    const CGFloat D2=D*D;
    
    /* delta is the discriminant, which tells us whether there is an intersection
        <0 -> no intersection
        =0 -> tangent
        >0 -> intersection
     */
    const CGFloat delta=r2*d2-D2;
    if (delta<0) {
        return NO;
    }
    
    /* There is an intersection so calculate the points */
    const CGFloat root_delta=sqrtf(delta);
    const CGFloat sign_dy=dy<0?-1:1;
    const CGFloat mod_dy=dy*sign_dy;
    
    const CGFloat X1=(D*dy+sign_dy*dx*root_delta)/d2;
    const CGFloat X2=(D*dy-sign_dy*dx*root_delta)/d2;
    
    const CGFloat Y1=((-D)*dx+mod_dy*root_delta)/d2;
    const CGFloat Y2=((-D)*dx-mod_dy*root_delta)/d2;
    
    *intersect1=NSMakePoint(X1+center.x, Y1+center.y);
    *intersect2=NSMakePoint(X2+center.x, Y2+center.y);
    
    return YES;
}


