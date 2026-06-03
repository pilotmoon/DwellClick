// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

// NOTE: requires QuartzCore.framework, for Core Animation

#import "NMPopupWindow.h"
#import "NMPopupWindowButton.h"
#import "NMPopupWindowBackgroundView.h"
#import "NMPopupWindowBorderView.h"
#import "NMGeometryUtils.h"
#import "NSWindow+NMAdditions.h"
#import "NMCoreUtils.h"

static BOOL _classicStyle;

NSString *const NMPrefsIgnoreTheme=@"IgnoreTheme";
NSString *const NMPrefsInitialAlpha=@"NMPopupInitialAlpha";
NSString *const NMPrefsFullAlpha=@"NMPopupFullAlpha";

@implementation NMPopupWindow
@synthesize mouseInWindow, currentButtons, fake, preferredNubPosition, keyboardMode, popupWindowDelegate;

+ (void)initialize
{
    if (self==[NMPopupWindow class]) {
        _classicStyle=[[NSUserDefaults standardUserDefaults] boolForKey:@"ClassicStyle"];
    }
}

+ (BOOL)classicStyle
{
    return _classicStyle;
}

+ (NSColor *)popupBackgroundColor;
{
    return [NSColor colorWithDeviceWhite:0.1 alpha:1.0];
}

+ (NSColor *)popupForegroundColor;
{
    return [NSColor colorWithDeviceWhite:1.0 alpha:1.0];
}

+ (NSColor *)popupHighlightBackgroundColor;
{
    const BOOL isGraphite=[[NSUserDefaults standardUserDefaults] integerForKey:@"AppleAquaColorVariant"]==6;
    const BOOL ignoreTheme=[[NSUserDefaults standardUserDefaults] boolForKey:NMPrefsIgnoreTheme];
    NSColor *const graphiteColor=[NSColor colorWithCalibratedRed:90.0/255 green:99.0/255 blue:109.0/255 alpha:1.0];
    //NSColor *const oldBlue=[NSColor colorWithDeviceRed:0.047 green:0.329 blue:0.944 alpha:1.0];
    NSColor *const newBlue=[NSColor colorWithCalibratedRed:0.0705882 green:0.247059 blue:0.933333 alpha:1.0];
    return (isGraphite&&!ignoreTheme)?graphiteColor:newBlue;
}

+ (NSColor *)popupHighlightForegroundColor;
{
    return [self popupForegroundColor];
}

+ (CGFloat)initialAlpha
{
    return [[NSUserDefaults standardUserDefaults] floatForKey:NMPrefsInitialAlpha];
}

+ (CGFloat)fullAlpha
{
    return [[NSUserDefaults standardUserDefaults] floatForKey:NMPrefsFullAlpha];
}

+ (NSTimeInterval)jumpInterval
{
    return 0.001;
}

+ (NSTimeInterval)fadeUpInterval
{
    return 0.08;
}

+ (NSTimeInterval)fadeDownInterval
{
    return 0.3;
}

- (id)init
{
	self=[super initWithBoxSize:NSZeroSize
					nubLocation:NSZeroPoint
					nubPosition:NMNubPositionBottom
						nubSize:10];	
	if (self) {
		// set content view
		[self setContentView:[[NMPopupWindowBackgroundView alloc] initWithFrame:NSZeroRect]];	
		
		// add border view
		borderView=[[NMPopupWindowBorderView alloc] initWithFrame:NSZeroRect];
		[borderView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [[self contentView] addSubview:borderView];
		
		// other stuff
		[self setLevel:NSScreenSaverWindowLevel-10];
		[self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        
        [self prepareFadeAnimation];
        [self fadeOutQuickly:YES];
	}
	return self;
}

- (void)orderOut:(id)sender {
	self.mouseInWindow=NO;
	[super orderOut:sender];
}
- (void)mouseEntered:(NSEvent *)theEvent {
	self.mouseInWindow=YES;
}
- (void)mouseExited:(NSEvent *)theEvent {
	self.mouseInWindow=NO;
}
- (void)keyDown:(NSEvent *)theEvent {
    [popupWindowDelegate popupKeyDown:theEvent];
}
- (void)keyUp:(NSEvent *)theEvent {
    [popupWindowDelegate popupKeyUp:theEvent];
}
- (BOOL)setUpButtons:(NSArray *)aButtons nubLocation:(NSPoint)aNubLocation
{
    const CGFloat borderWidth=[NMPopupWindow classicStyle]?1:0;
	NSSize size=NSZeroSize;
    BOOL resizeNeeded=NO;
	
	// note existing buttons
	NSMutableSet *existing=[NSMutableSet set];
	for (NSView *v in [[[self contentView] subviews] copy])
	{
		if ([v isKindOfClass:[NSButton class]])
		{
			[existing addObject:v];
		}
	}

	// add these buttons
	for (NMPopupWindowButton *button in aButtons)
	{
		// refresh size
		[button updateSize];
		
		// get existing button frame
		NSRect frame=[button frame];
		
		// position and add button
		[button setFrameOrigin:NSMakePoint(boxFrame.origin.x+borderWidth+size.width, boxFrame.origin.y+borderWidth)];
		[[self contentView] addSubview:button];
		
		// asjust our width and height
		size.width+=NSWidth(frame);
		size.height=NSHeight(frame);
		
		[existing removeObject:button];
	}
	
	// remove old from superview
	for (NSButton *b in existing)
	{
		[b removeFromSuperview];
	}
	
	// bring border view to top
    [[self contentView] addSubview:borderView positioned:NSWindowAbove relativeTo:nil];
	

	size.width+=borderWidth+borderWidth;
	size.height+=borderWidth+borderWidth;
	
    resizeNeeded=!NSEqualSizes(size, boxSize);
	if (resizeNeeded) {
		// window will need to be redisplayed
		[self orderOut:self];
	}
	
	[self setBoxSize:size nubLocation:aNubLocation];	
	
	// set tracking area
	if(ta) {
		[[self contentView] removeTrackingArea:ta];	
	}
	ta=[[NSTrackingArea alloc] initWithRect:[(NSView *)[self contentView] frame]
									options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
									  owner:self
								   userInfo:nil];
	[[self contentView] addTrackingArea:ta];		
	
	currentButtons=aButtons;
    return resizeNeeded;
}


- (void)changeButtons:(NSArray *)aButtons nubLocation:(NSPoint)aNubLocation
{
	if ([self setUpButtons:aButtons nubLocation:aNubLocation]) {
		[self drawNubWindow];
		[self showPopup];
	}
}

- (NMNubPosition)nubPositionForLocation:(NSPoint)location
{
    if (self.fake) {
        return self.nubPosition;   
    }
    
    NMNubPosition pos=(self.preferredNubPosition==NMNubPositionTop)?NMNubPositionTop:NMNubPositionBottom;

	CGFloat tolerance=[NMPopupWindowButton buttonHeight]+[NMPopupWindowButton nubSize];
	if (tolerance<22) {
		tolerance=22;
	}
	
	for (NSScreen *s in [NSScreen screens])
	{
		NSRect r=[s frame];
		if (pos==NMNubPositionBottom) {
			r.origin.y+=r.size.height-tolerance;
		}
		r.size.height=tolerance;
		if (NSPointInRect(location, r)) {
			pos=(pos==NMNubPositionBottom?NMNubPositionTop:NMNubPositionBottom);
			break;
		}
	}
    
    return pos;
}

- (void)preparePopupWithButtons:(NSArray *)aButtons nubLocation:(NSPoint)aNubLocation
{
	[self orderOut:self]; // make sure it's offscreen while messing
	[self setNubPosition:[self nubPositionForLocation:aNubLocation]];
	[self setUpButtons:aButtons nubLocation:aNubLocation];
	[self animateAlphaTo:0 duration:[NMPopupWindow jumpInterval]];
	[self drawNubWindow];
}

- (void)showPopupInKeyboardMode:(BOOL)state
{
    [self setKeyboardMode:state];
	[self setIgnoresMouseEvents:NO];
	[self orderFront:self];
    [self animateAlphaTo:[NMPopupWindow initialAlpha] duration:[NMPopupWindow fadeUpInterval]];
    if (self.keyboardMode) {
        [self makeKeyWindow];
    }
}

- (void)showPopup
{
	[self showPopupInKeyboardMode:NO];
}

- (void)makeFullAlpha
{
	[self animateAlphaTo:[NMPopupWindow fullAlpha] duration:[NMPopupWindow fadeUpInterval]];
}

- (void)fadeOutQuickly:(BOOL)quick
{
	[self setIgnoresMouseEvents:YES];
    [self setKeyboardMode:NO];
    [self animateAlphaTo:0 duration:quick?[NMPopupWindow jumpInterval]:[NMPopupWindow fadeDownInterval]];
}

- (void)drawNubWindow
{
	[self setFrame:nubWindowFrame display:NO];
	
	// weird hack to make transparent region draw right
	NSSize s=[(NSView *)[self contentView] frame].size;
	[self setContentSize:NSZeroSize];
	[self setContentSize:s];
}

- (CGFloat)principalNubOffset:(CGFloat)aBoxSide
{
    if (self.nubPosition==NMNubPositionBottom||self.nubPosition==NMNubPositionTop) {
        // find first primary button (centered)
        for (NMPopupWindowButton *b in self.currentButtons) {
            if (b.primaryButton) {
                return floor(NSMidX([b frame]));
            }
        }
    }
    
    return [super principalNubOffset:aBoxSide];
}

- (BOOL)canBecomeKeyWindow
{
    return self.keyboardMode;
}

@end
