// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMPopupWindowButton.h"
#import "NMPopupWindowButtonCell.h"
#import "NSImage+NMCopySize.h"
#import "NMMouseUtils.h"
#import "NMBlockUtils.h"
#import <NMKit/NMKit.h>

static NSString *PopPrefsPopupDistanceOverride=@"PopupDistanceOverride";

static NSDictionary *_textAttributes;
static CGFloat _buttonHeight;
static NSPoint _imageOffset;
static NSPoint _textPosition;
static CGFloat _nubSize;
static BOOL _legacyMode;

CGFloat NMPopupButtonHeight() {
    return _buttonHeight;
}

NSPoint NMPopupButtonTextPosition() {
    return _textPosition;
}

NSPoint NMPopupButtonImageOffset() {
    return _imageOffset;
}

NSDictionary *NMPopupButtonTextAttributes() {
    return _textAttributes;
}

@implementation NMPopupWindowButton
@synthesize mouseInsideButton, flashState, renderSize, primaryButton, leftmost, rightmost, buttonBlock;
@synthesize nextButton, prevButton, popupButtonDelegate, preserveColor, tip;

+ (void)setLegacyMode:(BOOL)state
{
    _legacyMode=state;
}
+ (NSPoint)imageOffset
{
	return _imageOffset;
}
+ (CGFloat)buttonHeight
{
	return _buttonHeight;
}
+ (NSPoint)textPosition
{
	return _textPosition;
}
+ (NSDictionary *)textAttributes
{
	return _textAttributes;
}
+ (CGFloat)nubSize
{
	return _nubSize;
}
+ (void)updateAppearance:(CGFloat)sizeSetting
{
	CGFloat fontSize;
	
	if (sizeSetting>0.9) {
        _buttonHeight=33;
		if (_legacyMode) {
            _imageOffset=NSMakePoint(2, 2);
        }
        else {
            _imageOffset=NSMakePoint(12, 5);
        }
		_textPosition=NSMakePoint(15, 6);
		fontSize=18.5;	
		_nubSize=15;
	}
	else if (sizeSetting>0.6) {
        _buttonHeight=28;
		if (_legacyMode) {
            _imageOffset=NSMakePoint(2, 2);
		}
        else {
            _imageOffset=NSMakePoint(10, 4);
        }
        _textPosition=NSMakePoint(13, 5.5);
		fontSize=15.5;	
		_nubSize=13;
	}
	else if (sizeSetting>0.3) {
        _buttonHeight=24;
		if (_legacyMode) {
            _imageOffset=NSMakePoint(2, 2);
		}
        else {
            _imageOffset=NSMakePoint(9, 4);
        }
        _textPosition=NSMakePoint(11, 5);
		fontSize=13;	
		_nubSize=11;
	}
	else {
        _buttonHeight=20;
		if (_legacyMode) {
            _imageOffset=NSMakePoint(2, 2);
		}
        else {
            _imageOffset=NSMakePoint(7, 3);
        }
        _textPosition=NSMakePoint(10, 4);
		fontSize=11;	
		_nubSize=10;
	}
    
    if (![NMPopupWindow classicStyle]) {
        _buttonHeight+=2;
        _imageOffset.y+=1;
    }

    NSNumber *dist=[[NSUserDefaults standardUserDefaults] objectForKey:PopPrefsPopupDistanceOverride];
    if ([dist isKindOfClass:[NSNumber class]]) {
        _nubSize=[dist floatValue];
    }
    NSFont *font=[NMPopupWindow classicStyle]?[NSFont boldSystemFontOfSize:fontSize]:[NSFont systemFontOfSize:fontSize];

	_textAttributes=@{NSForegroundColorAttributeName: [NMPopupWindow popupForegroundColor],
								NSFontAttributeName: font};
}

- (BOOL)pointInSelf:(NSPoint)unflippedPoint
{
	BOOL ins=NO;
	NSWindow *wnd=[self window];
	if (wnd&&[wnd isVisible]) {
		NSRect windowFrame=[wnd frame];
		NSRect rect=[self frame];
		rect.origin.x+=windowFrame.origin.x;
		rect.origin.y+=windowFrame.origin.y;
		ins=NSPointInRect(unflippedPoint, rect);
		//NMLogInfo(@"ins %d p%@ sf %@", ins, NSStringFromPoint(unflippedPoint), NSStringFromRect(rect));		
	}
	return ins;
}

- (void)removeFromSuperview
{
	[super removeFromSuperview];
	self.mouseInsideButton=NO;
	flashState=0;
}
- (void)viewDidMoveToWindow
{
	if([self pointInSelf:NSPointFromCGPoint(NMCurrentUnflippedMouseLocation())]) {
        self.mouseInsideButton=YES;
        self.activeButton=YES;
    }
	flashState=0;
    [self setNeedsDisplay:YES];    
	[[self window] display];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self.popupButtonDelegate mouseExitedButton:self];
    
	self.mouseInsideButton=NO;
    self.activeButton=![self.popupButtonDelegate shouldButtonRelinquishActive:self];  
    [self setNeedsDisplay:YES];
	[[self window] display];
}
- (void)mouseEntered:(NSEvent *)theEvent
{
    [self.popupButtonDelegate mouseEnteredButton:self];
    
	self.mouseInsideButton=YES;
    self.activeButton=YES;    
    [self setNeedsDisplay:YES];    
	[[self window] display];
}
- (void)mouseMoved:(NSEvent *)theEvent
{
    if (!self.mouseInsideButton||!self.activeButton) {
        [self mouseEntered:theEvent];
    }
}

- (void)flash
{
	flashState=1;
	[self setNeedsDisplay:YES];
	NMRunAsyncOnMainThreadWithDelay(0.1, ^{
		flashState=0;	
		[self setNeedsDisplay:YES];
	});
}

- (id)initWithFrame:(NSRect)frameRect
{
	frameRect=NSZeroRect;
	self = [super initWithFrame:frameRect];
	if (self) {
		[self setBordered:NO];
	}
	return self;
}

+ (Class)cellClass
{
	return [NMPopupWindowButtonCell class];
}

- (BOOL)isFlipped
{
	return NO;
}

- (void)updateTrackingAreas
{
	if (ta) {
		[self removeTrackingArea:ta];
	}
	ta=[[NSTrackingArea alloc] initWithRect:[self bounds] 
									options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways
									  owner:self
								   userInfo:0];
	[self addTrackingArea:ta];
	[super updateTrackingAreas];
}

- (void)updateSize
{
	NSSize frameSize=NSMakeSize(0,
								[[self class] buttonHeight]);
	
	// adjust size for text width if no image
	if (![self image])
	{
		// draw text
		NSSize textSize=[[self title] sizeWithAttributes:[[self class] textAttributes]];
		
		// set the button size (dodgy?)
		frameSize.width=floor(textSize.width+2*[[self class] textPosition].x);
	}
	else {
        CGFloat imageHeight=[[self class] buttonHeight]-2*[[self class] imageOffset].y;
        NSSize rawImageSize=[[self image] size];
        CGFloat imageWidth=(rawImageSize.width * imageHeight)/rawImageSize.height;
        frameSize.width=floor(imageWidth+2*[[self class] imageOffset].x);
        
		self.renderSize=NSMakeSize(imageWidth, imageHeight);
	}
	
	[self setFrameSize:frameSize];		
}

- (void)setTargetBlock:(NMBasicBlock)targetBlock
{
    self.buttonBlock=targetBlock;
    [self nm_setTargetBlock:self.buttonBlock];
}

- (void)setTitle:(NSString *)aString
{
	[super setTitle:aString];
	[self updateSize];
}

- (void)setImage:(NSImage *)image
{
	[super setImage:image];
	[self updateSize];
}

- (void)setActiveButton:(BOOL)state
{
    [self.popupButtonDelegate makeButtonActive:state?self:nil];
}

- (BOOL)isActiveButton
{
    return [self.popupButtonDelegate isButtonActive:self];
}

@end
