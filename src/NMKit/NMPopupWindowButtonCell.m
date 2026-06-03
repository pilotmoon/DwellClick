// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMPopupWindowButton.h"
#import "NMPopupWindowButtonCell.h"
#import "NMNubWindowView.h"
#import "NMPopupWindow.h"
#import "NSImage+NMCopySize.h"

@implementation NMPopupWindowButtonCell

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	NMPopupWindowButton * const button=(NMPopupWindowButton *)controlView;
	NMNubWindowView * const superNubView=(NMNubWindowView *)[controlView superview];
	if ([button isKindOfClass:[NMPopupWindowButton class]] &&
		 [superNubView isKindOfClass:[NMNubWindowView class]])
	{
		// make transform
		NSAffineTransform * const tx=[NSAffineTransform transform];
		const NSRect controlFrame=[controlView frame];
		[tx translateXBy:-controlFrame.origin.x yBy:-controlFrame.origin.y];
        
		// apply to clip path
		NSBezierPath * const mainBgPath=[tx transformBezierPath:[[superNubView ownerWindow] nubWindowPath]];
		[mainBgPath addClip];

		// highlight
        const BOOL highlight=[button isEnabled]&&((([button isActiveButton])&&button.flashState==0)||button.flashState==2);
		if (highlight) {
			NSColor * const highlightColor=[NMPopupWindow popupHighlightBackgroundColor];
			[highlightColor set];
			NSRectFill(frame);
            [mainBgPath setLineWidth:2.0];
            [mainBgPath stroke];
        }
		
		// image or text
		const Class viewClass=[button class];
		if (![self image]) {
            NSDictionary *attrs=[viewClass textAttributes];
            if (![button isEnabled]) {
                attrs=[[viewClass textAttributes] mutableCopy];
                ((NSMutableDictionary *)attrs)[NSForegroundColorAttributeName] = [[NMPopupWindow popupForegroundColor] colorWithAlphaComponent:0.7];
            }
            else if (highlight) {
                attrs=[[viewClass textAttributes] mutableCopy];
                ((NSMutableDictionary *)attrs)[NSForegroundColorAttributeName] = [NMPopupWindow popupHighlightForegroundColor];
            }
			[[self title] drawAtPoint:[viewClass textPosition]
					   withAttributes:attrs];
		}
		else {
            NSRect imageRect=NSZeroRect;
            imageRect.origin=[viewClass imageOffset];
            imageRect.size=[button renderSize];
            
            if ([button preserveColor]) {
                [[self image] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            }
            else {
                NSColor *foreground=highlight?[NMPopupWindow popupHighlightForegroundColor]:[NMPopupWindow popupForegroundColor];
                NSImage *tintedImage=[[self image] copyWithSize:imageRect.size colorTo:foreground];
                [tintedImage drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            }
        }
	}
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
    if ([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
        return self.title;
    }
    else {
        return [super accessibilityAttributeValue:attribute];
    }
}

@end
