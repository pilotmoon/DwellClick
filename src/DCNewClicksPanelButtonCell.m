// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCConstants.h"
#import "DCNewClicksPanelButton.h"
#import "DCNewClicksPanelButtonCell.h"
#import "NMKit/NMKit.h"

@implementation DCNewClicksPanelButtonCell


- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{

    DCNewClicksPanelButton *button=(DCNewClicksPanelButton *)controlView;
    NSRect imageRect=NSInsetRect(frame, frame.size.width*0.03, frame.size.height*0.03);
    NSColor *imageColor=nil;
    if ([(NSButton *)controlView state]==NSOnState) // on
    {
        imageColor=[NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
        NSShadow *shadow=[[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5]];
        [shadow setShadowOffset:NSZeroSize];
        [shadow setShadowBlurRadius:MIN(frame.size.width, frame.size.height)*0.05];
        [shadow set];        
    } 
    else if ([button isEnabled]&&button.mouseInsideButton) // mouse in
    { 
        imageColor=[NSColor colorWithCalibratedRed:0.9 green:0.9 blue:1.0 alpha:1.0];
    }
    else if ([button isEnabled])
    {
        imageColor=[NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
    }
    else {
        imageColor=[NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    }
    NSImage *tintedImage=[image copyWithSize:imageRect.size colorTo:imageColor];
    [tintedImage drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    DCNewClicksPanelButton *button=(DCNewClicksPanelButton *)controlView;
    if ([button isEnabled]&&button.mouseInsideButton&&button.flashState==0) 
    {
        if ([self isHighlighted]) {
            [[NSColor colorWithDeviceWhite:0.05 alpha:1.0] set];
        }
        else {
            [[NMPopupWindow popupHighlightBackgroundColor] set];
        }

        NSRectFill(frame);
    }
}

@end
