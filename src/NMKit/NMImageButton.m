// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMImageButton.h"
#import "NMImageButtonCell.h"

@interface NMImageButton ()
@property BOOL mouseIn;
@end

@implementation NMImageButton
@synthesize mouseIn=_mouseIn;

+ (Class)cellClass
{
	return [NMImageButtonCell class];
}

- (BOOL)isFlipped
{
    return NO;
}

- (void)setTintColor:(NSColor *)tintColor
{
    [[self cell] setTintColor:tintColor];
}

- (NSColor *)tintColor
{
    return [[self cell] tintColor];
}

- (void)setImage:(NSImage *)image
{
	[[self cell] setImage:image];
}

- (void)setAlternateImage:(NSImage *)image
{
	[[self cell] setAlternateImage:image];
}

- (void)removeAllTrackingAreas
{
    for (NSTrackingArea *ta in [self trackingAreas]) {
        [self removeTrackingArea:ta];
    }
}

- (void)updateTrackingAreas
{
    [self removeAllTrackingAreas];
    [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:[self bounds]
                                                       options:NSTrackingActiveAlways|NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved
                                                         owner:self
                                                      userInfo:0]];
}

- (id)initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect];
	if (self) {
		[self updateTrackingAreas];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];
    if (self) {
        [self updateTrackingAreas];
    }
	return self;
}

- (void)mouseEntered:(NSEvent *)event
{
	self.mouseIn=YES;
	[self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)event
{
	self.mouseIn=NO;
	[self setNeedsDisplay:YES];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	self.mouseIn=NO;
	[self setNeedsDisplay:YES];
}

- (void)setHidden:(BOOL)flag
{
    self.mouseIn=NO;
    [super setHidden:flag];
}

@end
