// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCAppCell.h"
#import "DCAppNameFormatter.h"


@implementation DCAppCell

- (void)setImageForCurrentObject
{	
	NSImage *result=nil;
	NMLogInfo(@"GETTING IMAGE for %@", [self objectValue]);
	NSString *path=[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[self objectValue]];
	if (path) {
		result=[[NSWorkspace sharedWorkspace] iconForFile:path];
		[result setSize:NSMakeSize(16, 16)];
	}
	[self setImage:result];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
	[self setImage:nil];
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	[self setImage:nil];
    [super selectWithFrame:aRect inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self setImageForCurrentObject];
	[super drawWithFrame:cellFrame inView:controlView];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (!(self = [super initWithCoder:aDecoder])) return nil;
	[self setFormatter:[[DCAppNameFormatter alloc] init]];
	return self;
}

@end
