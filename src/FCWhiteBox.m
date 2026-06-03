// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "FCWhiteBox.h"
#import <QuartzCore/QuartzCore.h>


@implementation FCWhiteBox

- (void)updateShadowPath
{
    CGPathRef shadowPath=CGPathCreateWithRoundedRect(NSRectToCGRect([self bounds]), 12.0, 12.0, NULL);
    self.layer.shadowPath=shadowPath;
    CGPathRelease(shadowPath);
}

- (void)configureShadow
{
    self.wantsLayer=YES;
    self.layer.masksToBounds=NO;
    self.layer.shadowColor=[[NSColor colorWithDeviceWhite:0.0 alpha:0.28] CGColor];
    self.layer.shadowOpacity=1.0;
    self.layer.shadowRadius=7.0;
    self.layer.shadowOffset=NSMakeSize(0.0, -4.0);
    [self updateShadowPath];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self configureShadow];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self updateShadowPath];
}

-(void)drawRect:(NSRect)dirtyRect
{
	NSRect windowRect=[self bounds];
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:windowRect xRadius:12.0 yRadius:12.0];
	
	// fill background	
	NSColor *startColor  = [NSColor colorWithDeviceWhite:0.95 alpha:1.0];
	NSColor *endColor    = [NSColor colorWithDeviceWhite:1.000 alpha:1.0];
	NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:startColor, 0.0, endColor, 1.0, nil];
	[gradient drawInBezierPath:path angle:90];
}

@end
