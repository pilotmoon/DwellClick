// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMNubWindow.h"

extern NSString *const NMPrefsIgnoreTheme;
extern NSString *const NMPrefsInitialAlpha;
extern NSString *const NMPrefsFullAlpha;

@protocol NMPopupWindowDelegate <NSObject>
- (void)popupKeyDown:(NSEvent *)theEvent;
- (void)popupKeyUp:(NSEvent *)theEvent;
@end

@interface NMPopupWindow : NMNubWindow {
	BOOL mouseInWindow;
    BOOL keyboardMode;
	NSTrackingArea *ta;
	NSArray *currentButtons;
    __unsafe_unretained id<NMPopupWindowDelegate> popupWindowDelegate;

	// the gloss and border
	NSView *borderView;
    BOOL fake;
    
    NMNubPosition preferredNubPosition;
}
@property BOOL fake;
@property BOOL mouseInWindow;
@property BOOL keyboardMode;
@property (readonly) NSArray *currentButtons;
@property NMNubPosition preferredNubPosition;
@property (unsafe_unretained) id<NMPopupWindowDelegate> popupWindowDelegate;

+ (BOOL)classicStyle;
+ (NSColor *)popupBackgroundColor;
+ (NSColor *)popupForegroundColor;
+ (NSColor *)popupHighlightBackgroundColor;
+ (NSColor *)popupHighlightForegroundColor;

- (NMNubPosition)nubPositionForLocation:(NSPoint)location;
- (void)preparePopupWithButtons:(NSArray *)aButtons nubLocation:(NSPoint)aNubLocation;
- (void)changeButtons:(NSArray *)aButtons nubLocation:(NSPoint)aNubLocation;
- (void)showPopup;
- (void)showPopupInKeyboardMode:(BOOL)state;
- (void)makeFullAlpha;
- (void)fadeOutQuickly:(BOOL)quick;

@end
