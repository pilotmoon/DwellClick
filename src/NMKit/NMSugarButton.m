// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMSugarButton.h"
#import "NMSugarButtonCell.h"

@interface NMSugarButton ()
@property BOOL mouseIn;
@end

@implementation NMSugarButton

+ (Class)cellClass
{
	return [NMSugarButtonCell class];
}

- (NSColor *)glowGolor
{
	return [(NMSugarButtonCell *)[self cell] glowColor];
}

- (void)setGlowGolor:(NSColor *)color
{
	[(NMSugarButtonCell *)[self cell] setGlowColor:color];
}

- (NSColor *)textColor
{
	return [(NMSugarButtonCell *)[self cell] backgroundColor];
}

- (void)setTextColor:(NSColor *)color
{
	[(NMSugarButtonCell *)[self cell] setTextColor:color];
}

- (NSColor *)backgroundColor
{
	return [(NMSugarButtonCell *)[self cell] backgroundColor];
}

- (void)setBackgroundColor:(NSColor *)color
{
	[(NMSugarButtonCell *)[self cell] setBackgroundColor:color];
}

- (BOOL)isFlipped
{
	return YES;
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
