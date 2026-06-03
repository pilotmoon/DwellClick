// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

typedef enum {
	NMNubPositionBottom,
	NMNubPositionRight,
	NMNubPositionTop,
	NMNubPositionLeft
} NMNubPosition;

@interface NMNubWindow : NSPanel {
	
	/**************************
	 The 4 principal parameters
	 **************************/
	
	// where the nub should point to
	NSPoint nubLocation;
	
	// size of the box part of the window
	NSSize boxSize;
	
	// top/bottom/left/right
	NMNubPosition nubPosition;
	
	// how far it sticks out 
	CGFloat nubSize;
	
	// should the nub move when window is near edge
	BOOL avoidEdgeOverlap;
	
	/*********************
	 Internally calculated
	 *********************/
	// offset of nub 
	CGFloat nubOffset;
	// the actual path that defines the window
	NSBezierPath *nubWindowPath;
	// window frame
	NSRect nubWindowFrame;
	// frame of box (window coords)
	NSRect boxFrame;
}
@property NSPoint nubLocation;
@property NSSize boxSize;
@property NMNubPosition nubPosition;
@property CGFloat nubSize;
@property BOOL avoidEdgeOverlap;

@property (readonly) CGFloat nubOffset;
@property (readonly) NSBezierPath *nubWindowPath;
@property (readonly) NSRect	nubWindowFrame;
@property (readonly) NSRect	boxFrame;

- (id)initWithBoxSize:(NSSize)aBoxSize
		  nubLocation:(NSPoint)aNubLocation
		  nubPosition:(NMNubPosition)aNubPosition
			  nubSize:(CGFloat)aNubSize;

- (void)setBoxSize:(NSSize)aBoxSize
	   nubLocation:(NSPoint)aNubLocation
	   nubPosition:(NMNubPosition)aNubPosition
		   nubSize:(CGFloat)aNubSize;

- (void)setBoxSize:(NSSize)aBoxSize
	   nubLocation:(NSPoint)aNubLocation;

- (void)drawNubWindow;

- (CGFloat)cornerRadius;

- (CGFloat)principalNubOffset:(CGFloat)aBoxSide;

@end
