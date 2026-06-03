// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMTipWindow.h"
#import "NMTipWindowView.h"

@implementation NMTipWindow

static NSFont *_font;

// designated initializer
- (id)init
{
	// start with zero window
    self = [super initWithContentRect:NSZeroRect
                            styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask
                              backing:NSBackingStoreBuffered
                                defer:NO];
    if (self) {
        // set window parameters
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        
        _font=[NSFont systemFontOfSize:11];
		[self setContentView:[[NMTipWindowView alloc] initWithFrame:NSZeroRect]];
        [(NMTipWindowView *)[self contentView] setFont:_font];
        
        [self setIgnoresMouseEvents:YES];
        [self setLevel:NSScreenSaverWindowLevel-9];
        

    }
    
    return self;
}

- (void)prepareWithText:(NSString *)text andLocation:(NSPoint)location
{
    CGFloat tipHeight=20;
    CGFloat tipOffset=20;
    CGFloat tipWidth=[text sizeWithAttributes:@{NSFontAttributeName: _font}].width+6;
    
    
    
    BOOL below=YES, right=YES;
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect bframe=[screen frame];
        NSRect rframe=bframe;
        bframe.size.height=tipHeight+tipOffset;
        rframe.origin.x+=(rframe.size.width-tipWidth);
        rframe.size.width=tipWidth;        
        if (NSPointInRect(location, bframe)) {
            below=NO;
        }
        if (NSPointInRect(location, rframe)) {
            right=NO;
        }
    }
    
    [(NMTipWindowView *)[self contentView] setText:text];
    [self setFrame:NSMakeRect((right?location.x:location.x-tipWidth), location.y+(below?(-tipHeight-tipOffset):5), tipWidth, tipHeight) display:YES];
}

@end
