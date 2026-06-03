// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMNubWindow.h"
#import "NSBezierPath+NMNub.h"
#import "NMCoreUtils.h"

@implementation NMNubWindow
@synthesize nubLocation, boxSize, nubPosition, nubSize, nubOffset, nubWindowPath, nubWindowFrame, boxFrame, avoidEdgeOverlap;

static NSRect _pointScreenRect(NSPoint point)
{
	for (NSScreen * s in [NSScreen screens])
	{
		NSRect frame=[s frame];
		if (NSPointInRect(point, frame)) {
			return frame;
		}
	}
	return NSZeroRect;
}

- (CGFloat)principalNubOffset:(CGFloat)aBoxSide
{
    return floor(aBoxSide*0.5);
}

- (CGFloat)nubOffsetForBoxSide:(CGFloat)aBoxSide
                         point:(CGFloat)aPoint
                           min:(CGFloat)aMin
                           max:(CGFloat)aMax
                    avoidEdges:(BOOL)avoidEdges
{
   
	CGFloat halfSide=[self principalNubOffset:aBoxSide];
    CGFloat overlap=0;
    CGFloat maxOverlap=-nubSize-[self cornerRadius];
	
	if (avoidEdges) {
		CGFloat boxLeft=aPoint-halfSide;
		CGFloat boxRight=aPoint+(aBoxSide-halfSide);
		
		if (boxLeft<aMin) {
            maxOverlap+=halfSide; /**************************************************** http://fdhfj */
			overlap=boxLeft-aMin;
			if (overlap<(-maxOverlap)) {
				overlap=(-maxOverlap);
			}
		}
		else if (boxRight>aMax) {
            maxOverlap+=(aBoxSide-halfSide);
            overlap=boxRight-aMax;		
			if (overlap>maxOverlap) {
				overlap=maxOverlap;
			}
		}		
	}
	
	return halfSide+overlap;		 
}

- (CGFloat)cornerRadius
{
    return 6.0;
}

// update the current path
- (void)updateGeometry
{
	// calculate container and nub offset
	NSRect container=NSZeroRect;	
	container.size=boxSize;	
	boxFrame=container;
	
	// find screen containing mouse
	NSRect mouseScreenRect=_pointScreenRect(nubLocation);
	switch (nubPosition) {
		case NMNubPositionBottom:
		case NMNubPositionTop:		
			nubOffset=[self nubOffsetForBoxSide:boxSize.width
                                          point:nubLocation.x
                                            min:mouseScreenRect.origin.x
                                            max:mouseScreenRect.origin.x+NSWidth(mouseScreenRect)
                                     avoidEdges:avoidEdgeOverlap];
            container.size.height+=nubSize;
			break;
		case NMNubPositionRight:
		case NMNubPositionLeft:
            nubOffset=[self nubOffsetForBoxSide:boxSize.height  
                                          point:nubLocation.y
                                            min:mouseScreenRect.origin.y
                                            max:mouseScreenRect.origin.y+NSHeight(mouseScreenRect)
                                     avoidEdges:avoidEdgeOverlap];
			container.size.width+=nubSize;
			break;
		default:
			break;
	}
	
	// caluclate window path
	nubWindowPath=[NSBezierPath bezierPathWithNubRect:container
											   radius:[self cornerRadius]
										  nubPosition:nubPosition
											  nubSize:nubSize 
											nubOffset:nubOffset];
	
	// calculate relative nub location
	NSPoint nubLocationRelative=NSZeroPoint;
	switch (nubPosition) {
		case NMNubPositionBottom:
			boxFrame.origin.y+=nubSize;
			nubLocationRelative=NSMakePoint(nubOffset, -1);
			break;
		case NMNubPositionLeft:		
			boxFrame.origin.x+=nubSize;
			nubLocationRelative=NSMakePoint(-1, nubOffset);
			break;
		case NMNubPositionTop:
			nubLocationRelative=NSMakePoint(nubOffset, NSHeight(container)+1);
			break;
		case NMNubPositionRight:
			nubLocationRelative=NSMakePoint(NSWidth(container)+1, nubOffset);
			break;
		default:
			break;
	}

	// calculate frame 
	nubWindowFrame=container;
	nubWindowFrame.origin.x+=nubLocation.x-nubLocationRelative.x;
	nubWindowFrame.origin.y+=nubLocation.y-nubLocationRelative.y;
}

// redraw with current geometry
- (void)drawNubWindow
{
	[self setFrame:nubWindowFrame display:YES];
    [[[self contentView] superview] setNeedsDisplay:YES];
}

#pragma mark Compound setters

// set all 4 params
- (void)setBoxSize:(NSSize)aBoxSize
	   nubLocation:(NSPoint)aNubLocation
	   nubPosition:(NMNubPosition)aNubPosition
		   nubSize:(CGFloat)aNubSize
{
	boxSize=aBoxSize;
	nubLocation=aNubLocation;
	nubPosition=aNubPosition;
	nubSize=aNubSize;
	[self updateGeometry];
    [self drawNubWindow];
}

// just set size and location
- (void)setBoxSize:(NSSize)aBoxSize
	   nubLocation:(NSPoint)aNubLocation
{
	boxSize=aBoxSize;
	nubLocation=aNubLocation;
	[self updateGeometry];
    [self drawNubWindow];
}

#pragma mark Observer for single setters

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	[self updateGeometry];
    [self drawNubWindow];
}

#pragma mark Initializers

// designated initializer
- (id)initWithBoxSize:(NSSize)aBoxSize
		  nubLocation:(NSPoint)aNubLocation
		  nubPosition:(NMNubPosition)aNubPosition
			  nubSize:(CGFloat)aNubSize
{
	// start with zero window
    self = [super initWithContentRect:NSZeroRect
					 styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask
					   backing:NSBackingStoreBuffered
						 defer:NO];
    if (!self) return nil;
	
	// set window parameters
	[self setOpaque:NO];
	[self setBackgroundColor:[NSColor clearColor]];
	
	// set observer for changes
	[self addObserver:self forKeyPath:@"boxSize" options:0 context:0];
	[self addObserver:self forKeyPath:@"nubLocation" options:0 context:0];
	[self addObserver:self forKeyPath:@"nubPosition" options:0 context:0];
	[self addObserver:self forKeyPath:@"nubSize" options:0 context:0];
	
	// set overlap param
	[self setAvoidEdgeOverlap:YES];
	
	// set geometry
	[self setBoxSize:aBoxSize
		 nubLocation:aNubLocation
		 nubPosition:aNubPosition
			 nubSize:aNubSize];		

    return self;
}

@end
