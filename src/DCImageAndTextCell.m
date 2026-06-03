// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCImageAndTextCell.h"

@implementation DCImageAndTextCell

- (void)dealloc {
    image = nil;
}

- copyWithZone:(NSZone *)zone
{
    DCImageAndTextCell *cell = (DCImageAndTextCell *)[super copyWithZone:zone];
    cell->image = image;
    return cell;
}

- (void)setImage:(NSImage *)anImage
{
    if (anImage != image)
	{
        image = anImage;
    }
}

- (NSImage *)image
{
    return image;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (image != nil)
	{
        NSRect imageFrame;
        NSSize imageSize=[image size];
		NSSize canvasSize={imageSize.width*(16.0/imageSize.height),16};
		
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + canvasSize.width, NSMinXEdge);
        if ([self drawsBackground])
		{
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += 3;
		imageFrame.size=canvasSize;
		
		NMLogInfo(@"controlview flipped? : %d", [controlView isFlipped]);
        if ([controlView isFlipped]) {
			imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
			imageFrame.origin.y -= imageFrame.size.height; // bit of a hack but works... dunno quite why
		}
        else {
			imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
		}

		[image drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:0];
    }
    [NSGraphicsContext saveGraphicsState];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [super drawWithFrame:cellFrame inView:controlView];
    [NSGraphicsContext restoreGraphicsState];
}

- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width*(16.0/[image size].height) : 0) + 3;
    return cellSize;
}

@end

