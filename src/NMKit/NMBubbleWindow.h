// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMNubWindow.h"

typedef enum {
    NMAttachmentOptionMin,
    NMAttachmentOptionMid,
    NMAttachmentOptionMax
} NMAttachmentOption;


@class NMBubbleWindowView, NMBubbleCloseButton;

@interface NMBubbleWindow : NMNubWindow {
    // content view for the window
	NSView *childContentView;
    
    // block which gives the coordinates to position the window
	NSPoint(^centerBlock)(void);
    
    // attention animation
    NSInteger animPos;
    NSTimer *animTimer;
    
    // window attachment
    NSWindow *_attachedWindow;
    NMAttachmentOption _attachedXPos;
    CGFloat _attachedXOff;
    NMAttachmentOption _attachedYPos;
    CGFloat _attachedYOff;
    __strong id _moveNotificationObject;
    __strong id _resizeNotificationObject;
    
    // close button
    NMBubbleCloseButton *_closeButton;
}

- (void)setView:(NSView *)view;
- (NSView *)backgroundView;
- (void)bringAttentionToWindow;
- (void)attachToWindow:(NSWindow *)window
                  xPos:(NMAttachmentOption)xPos
               xOffset:(CGFloat) xOff
                  yPos:(NMAttachmentOption)xPos 
               yOffset:(CGFloat) yOff;

@property (copy) NSPoint (^centerBlock)(void);
@property BOOL hasCloseButton;

@end
