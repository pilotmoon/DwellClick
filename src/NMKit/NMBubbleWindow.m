// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMBubbleWindow.h"
#import "NMBubbleWindowView.h"
#import "NMBubbleCloseButton.h"

#import "NMEscapableItem.h"
#import <Carbon/Carbon.h>

#define BUBBLE_NUB_SIZE 9.0

@implementation NMBubbleWindow
@synthesize centerBlock;

- (CGFloat)cornerRadius
{
	return 9.0;
}

- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(NSUInteger)windowStyle
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)deferCreation
{
	self = [super initWithBoxSize:contentRect.size
					  nubLocation:NSZeroPoint
					  nubPosition:NMNubPositionTop
						  nubSize:BUBBLE_NUB_SIZE];
    if (self) {
        self.centerBlock=^{
            return NSMakePoint(500, 500); // arbitrary default; should always be overriden
        };
    }
	return self;
}

- (void)setContentSize:(NSSize)newSize
{
	[self setBoxSize:newSize];	
}

- (void)drawNubWindow {
    [childContentView setFrame:self.boxFrame];
    [super drawNubWindow];
}

+ (Class)contentViewClass
{
    return [NMBubbleWindowView class];
}
   
//
// setContentView:
//
// Keep our frame view as the content view and make the specified "aView"
// the child of that.
//
- (void)setContentView:(NSView *)aView
{
    // don't set same content view again
	if ([childContentView isEqualTo:aView]) {
		return;
	}
	
    // get size of window to bounds
	NSRect bounds = [self frame];
	bounds.origin = NSZeroPoint;
	
    // add the actual bubble view
	NMBubbleWindowView *frameView = [super contentView];
	if (!frameView) {
		frameView = [[[[self class] contentViewClass] alloc] initWithFrame:bounds];		
		[super setContentView:frameView];
	}
	
    // remove existing view if there is one
	if (childContentView) {
		[childContentView removeFromSuperview];
	}
    
    // set the new child
	childContentView = aView;
    [self setBoxSize:[aView frame].size];
    [childContentView setFrame:self.boxFrame];

    // finally add the subview
	[frameView addSubview:childContentView];
}

- (NSView *)contentView
{
	return childContentView;
}

- (NSView *)backgroundView
{
    return [super contentView];
}

- (void)setView:(NSView *)view
{
	NSSize size=[view frame].size;
	[self setContentView:view];
	[self setContentSize:size];
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (void)center
{
	if (centerBlock) {
		[self setNubLocation:centerBlock()];
	}
	[self drawNubWindow];
}

#pragma mark Attention Animation

- (void)animTimer
{
    if (animPos>10) {
        [animTimer invalidate];
        animTimer=nil;
        [self center];
        return;
    }
    NSRect r=[self frame];
    animPos++;
    int dir=animPos>5?-1:1;
    r.origin.y+=dir;
    [self setFrameOrigin:r.origin];
}

- (void)bringAttentionToWindow
{
    if (![self isVisible]) {
        return;
    }
	[self center];
    animPos=0;
    animTimer=[NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animTimer) userInfo:0 repeats:YES];
}

#pragma mark Window Attachment

- (void)attachToWindow:(NSWindow *)window
                  xPos:(NMAttachmentOption)xPos
               xOffset:(CGFloat)xOff
                  yPos:(NMAttachmentOption)yPos
               yOffset:(CGFloat)yOff
{
    _attachedWindow=window;
    __unsafe_unretained NSWindow *weakWindow=window;
    self.centerBlock=^{
        __strong NSWindow *strongWindow=weakWindow;
        NSRect frame=[strongWindow frame];
        
        NSPoint result=NSZeroPoint;
        switch (xPos) {
            case NMAttachmentOptionMin:
                result.x=NSMinX(frame);
                break;
            case NMAttachmentOptionMid:
                result.x=NSMidX(frame);
                break;
            case NMAttachmentOptionMax:
                result.x=NSMaxX(frame);
                break;                
            default:
                break;
        }
        switch (yPos) {
            case NMAttachmentOptionMin:
                result.y=NSMinY(frame);
                break;
            case NMAttachmentOptionMid:
                result.y=NSMidY(frame);
                break;
            case NMAttachmentOptionMax:
                result.y=NSMaxY(frame);
                break;                
            default:
                break;
        }
        result.x+=xOff;
        result.y+=yOff;
        return result;
    };
    _moveNotificationObject=[[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidMoveNotification 
                                                                              object:_attachedWindow
                                                                               queue:nil
                                                                          usingBlock:^(NSNotification *note) {
                                                                              [self center];
                                                                          }];
    _resizeNotificationObject=[[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResizeNotification 
                                                                                object:_attachedWindow
                                                                                 queue:nil
                                                                            usingBlock:^(NSNotification *note) {
                                                                                [self center];
                                                                            }];
    [self center];
}

- (void)setHasCloseButton:(BOOL)hasCloseButton
{
    [self willChangeValueForKey:@"hasCloseButton"];
    if (hasCloseButton&&!_closeButton) {
        _closeButton=[[NMBubbleCloseButton alloc] initWithFrame:NSMakeRect(9, [self frame].size.height-self.nubSize-27, 18, 18)];
        [_closeButton setTarget:self];
        [_closeButton setAction:@selector(close)];
        [[self contentView] addSubview:_closeButton];
    }
    else if (!hasCloseButton&&_closeButton) {
        [_closeButton removeFromSuperview];
        _closeButton=nil;
    }
    [self didChangeValueForKey:@"hasCloseButton"];
}

- (BOOL)hasCloseButton
{
    return !!_closeButton;
}

- (void)keyDown:(NSEvent *)theEvent
{
    if ([theEvent keyCode]==kVK_Escape) {
        if ([[self delegate] respondsToSelector:@selector(escapeKeyWasPressed)]) {
            [(id<NMEscapableItemDelegate>)[self delegate] escapeKeyWasPressed];
        }
    }
}

@end
