// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMSugarButtonCell.h"
#import "NMSugarButton.h"
#import "NMKit/NSImage+NMCopySize.h"

static NSShadow *_shadow;

@interface NSCell (FCButtonCellPrivate)
- (NSDictionary *)_textAttributes;
- (NSColor *)interiorColor;
@end

@implementation NMSugarButtonCell
@synthesize backgroundColor, textColor, glowColor;

+ (void)initialize
{
	if (self==[NMSugarButtonCell class]) {
		_shadow=[[NSShadow alloc] init];
		[_shadow setShadowColor:[NSColor colorWithDeviceWhite:0 alpha:0.2]];
		[_shadow setShadowBlurRadius:3.0];
		[_shadow setShadowOffset:NSMakeSize(0, 0)];
	}
}


- (void)defaults
{
	[self setButtonType:NSMomentaryPushInButton];
	[self setBezelStyle:NSRoundRectBezelStyle];
	backgroundColor=[NSColor colorWithDeviceWhite:0.1 alpha:1.0];
    textColor=[NSColor colorWithCalibratedWhite:1.0 alpha:1];
}

- (id)initWithCoder:(NSCoder *)aCoder
{
	self=[super initWithCoder:aCoder];
	if (self) {
		[self defaults];
	}
	return self;
}

- (id)initTextCell:(NSString *)aString
{
	self=[super initTextCell:aString];
	if (self) {
		[self defaults];
	}
	return self;
}
- (id)initImageCell:(NSImage *)anImage
{
	self=[super initImageCell:anImage];
	if (self) {
		[self defaults];
	}
	return self;
}

//- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
//{
//	CGFloat roundedRadius = 3.0f;
//	
//	// Outer border
//	if (borderColor) {
//		NSBezierPath *outerClip = [NSBezierPath bezierPathWithRoundedRect:frame 
//																  xRadius:roundedRadius 
//																  yRadius:roundedRadius];
//		[outerClip addClip];
//		[borderColor set];
//		NSRectFill(frame);
//		
//	}
//	
//	CGFloat inset=borderColor?1.0f:0.0f;
//	// Background fill and gradient
//	NSBezierPath *backgroundPath = 
//    [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame, inset, inset) 
//                                    xRadius:roundedRadius 
//                                    yRadius:roundedRadius];
//	[backgroundPath addClip];
//	[backgroundColor set];
//	NSRectFill(frame);
//	
//	// draw the gradient
//	NSRect gradBounds = [backgroundPath bounds];
//	gradBounds.size.height*=0.5;
//	[[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.35]
//								   endingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.06]]
//	 drawInRect:gradBounds angle:90];
//	
//	// Inner light stroke
//	[[NSColor colorWithDeviceWhite:1.0f alpha:0.02f] setStroke];
//	[[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame, 2.5f, 2.5f) 
//									 xRadius:roundedRadius 
//									 yRadius:roundedRadius] stroke];
//	
//	// Draw darker overlay if button is pressed
//	if([self isHighlighted]) {
//		/*[[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame, 2.0f, 2.0f) 
//										 xRadius:roundedRadius 
//										 yRadius:roundedRadius] setClip];*/
//		[[NSColor colorWithCalibratedWhite:0.0f alpha:0.35] setFill];
//		NSRectFillUsingOperation(frame, NSCompositeSourceOver);
//	}
//}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    NMSugarButton *sugarButton=(NMSugarButton *)controlView;
    // Draw button background
	const CGFloat roundedRadius = 3.0f;
	NSBezierPath *const backgroundPath=[NSBezierPath bezierPathWithRoundedRect:frame
                                                                 xRadius:roundedRadius
                                                                 yRadius:roundedRadius];
	[backgroundPath addClip];
    
    NSColor *adjustedBgCol=sugarButton.mouseIn?[backgroundColor highlightWithLevel:0.1]:backgroundColor;
	[adjustedBgCol set];
    
    // Draw with shadow
    [NSGraphicsContext saveGraphicsState];
    NSShadow *const shadow=[[NSShadow alloc] init];
    shadow.shadowColor=[NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
    shadow.shadowBlurRadius=2;
    shadow.shadowOffset=NSMakeSize(0, -1);
    [shadow set];
	NSRectFill(frame);
    [NSGraphicsContext restoreGraphicsState];

	// Draw darker overlay if button is pressed
	if([self isHighlighted]) {
		[[NSColor colorWithCalibratedWhite:0.0f alpha:0.35] setFill];
		NSRectFillUsingOperation(frame, NSCompositeSourceOver);
	}
}


- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSButton *)controlView
{	
//	NMLogInfo(@"draw image %@ %@", self, [controlView title]);
	[_shadow set];
	[super drawImage:image withFrame:NSInsetRect(frame,2,2) inView:controlView];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSButton *)controlView
{
//	NMLogInfo(@"draw title %@ %@", self, [controlView title]);
//	return [super drawTitle:title withFrame:frame inView:controlView];
    [title drawInRect:frame];
    return frame;
}

- (NSDictionary *)_textAttributes
{
	NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
	[attributes addEntriesFromDictionary:[super _textAttributes]];
	attributes[NSForegroundColorAttributeName] = [self interiorColor];
	
    if ([self glowColor]) {
        NSShadow *glow=[[NSShadow alloc] init];
		[glow setShadowColor:self.glowColor];
		[glow setShadowBlurRadius:3.0];
		[glow setShadowOffset:NSMakeSize(0, 0)];
        attributes[NSShadowAttributeName] = glow;
    }
    else { 
        attributes[NSShadowAttributeName] = _shadow;
    }
        
	return attributes;
}

- (NSColor *)interiorColor
{
	NSColor *interiorColor;
	
	if ([self isEnabled]&&![self isHighlighted])
		interiorColor = textColor;
	else
		interiorColor = [textColor blendedColorWithFraction:0.4 ofColor:[NSColor blackColor]];
	
	return interiorColor;
}


@end
