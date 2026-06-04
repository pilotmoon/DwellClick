// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NSImage+NMCopySize.h"
#import "NMCUtils.h"

@implementation NSImage(NMCopySize)

+ (CGFloat)nm_backingScaleFactor
{
    NSScreen *screen=[NSScreen mainScreen];
    CGFloat scale=[screen backingScaleFactor];
    return scale<1.0 ? 1.0 : scale;
}

- (NSImage *)copyWithSize:(NSSize)size colorTo:(NSColor *)color
{
	[NSGraphicsContext saveGraphicsState];

	if (size.width==0 && size.height==0) {
		size=[self size];
	}
	    
	// new image to draw into
	CGFloat scale=[NSImage nm_backingScaleFactor];
	NSImage *new=[NSImage blankBitmapOfSize:size scale:scale];
	NSBitmapImageRep *rep=(NSBitmapImageRep *)[new representations][0];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
		
	// draw it (high quality)
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	NSRect dst=NSZeroRect;
	dst.size=size;
	[self drawInRect:dst fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];
	
	// recolor
	if (color) {
		[rep colorizeByMappingGray:0.5 toColor:color blackMapping:color whiteMapping:color];		
	}
	
	[NSGraphicsContext restoreGraphicsState];
	return new;
}

- (NSImage *)copyWithSize:(NSSize)size
{
	return [self copyWithSize:size colorTo:nil];
}


+ (NSImage *)blankBitmapOfSize:(NSSize)size;
{
	return [self blankBitmapOfSize:size scale:1.0];
}

+ (NSImage *)blankBitmapOfSize:(NSSize)size scale:(CGFloat)scale;
{
	if (scale<1.0) {
		scale=1.0;
	}
	NSInteger pixelsWide=ceil(size.width*scale);
	NSInteger pixelsHigh=ceil(size.height*scale);
    
	NSBitmapImageRep *rep=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																	  pixelsWide:pixelsWide
																	  pixelsHigh:pixelsHigh
																   bitsPerSample:8
																 samplesPerPixel:4
																		hasAlpha:YES
																	isPlanar:NO
															  colorSpaceName:NSDeviceRGBColorSpace
																 bytesPerRow:0
																bitsPerPixel:0];
	
	// blank the image
	unsigned char *data=[rep bitmapData];
	NSUInteger count=[rep bytesPerPlane];
	NM_memset(data, 0, count);
		
	NSImage *img=[[NSImage alloc] initWithSize:size];
	[rep setSize:size];
	[img addRepresentation:rep];
	return img;
}

@end
