// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "NMPopupWindowButton.h"
#import "NMPopupWindow.h"
#import "NMBlockUtils.h"
#import "NMTipWindow.h"

@class NMPoint;

extern NSString *const NMPopupWillAppearGlobalNotification;
extern NSString *const NMPopupWillAppearNotification;
extern NSString *const NMPopupDidCancelNotification;
extern NSString *const NMPopupBoxKey;
extern NSString *const NMPopupReasonKey;
extern NSString *const NMPopupReasonMouseAway;
extern NSString *const NMPopupReasonScrollWheel;
extern NSString *const NMPopupReasonActionSelected;
extern NSString *const NMPopupReasonMouseClick;
extern NSString *const NMPopupReasonKeyPress;
extern NSString *const NMPopupReasonOther;

@interface NMPopupController : NSObject <NSWindowDelegate, NMPopupWindowDelegate, NMPopupWindowButtonDelegate> {
@private
    NMPopupWindow *_popupWindow;
    
    // the location of the current or most recent popup
	NSPoint _currentLocation;
    NSArray *_currentButtons;
	
	// popup has been cancelled
	BOOL _cancelled;
	
	// popup is active (is being displayed)
	BOOL _active;
	
	// the button that the mouse is pointing at, or nil if none
	NSButton *_mouseButton;	
    
    CGFloat _popupSize;
    BOOL _popupUnder;
    
    NSRect _box;
    NSRect _mouseBox;
    BOOL _enableBoxDetect;
    
    BOOL _nubless;
    
    id _monitor;
    CGFloat _scrollDistance;
    NSString *_noteObjectString;
    NSTimer *_cancelTimer;
    
    NSTimeInterval _cancelTimeInterval;
    NSTimeInterval _longCancelTimeInterval;
    BOOL _mouseStartsOutside;
    CGFloat _boxDistance;
    CGFloat _boxNubsideDistance;
    NSTimeInterval _actionRunDelay;
    
    NMPopupWindowButton *_activeButton;
    NSRect _lastClickedButtonFrame;

    NSTimer *_tipTimer;
    NSTimer *_tipCancelTimer;
    BOOL _isShowingTip;
    
    NMTipWindow *_tipWindow;
    
}
@property NSPoint currentLocation;
@property (readonly) NMPopupWindow *popupWindow;
@property (readonly) BOOL cancelled;
@property (readonly) BOOL active;
@property (readonly, getter=isAlive) BOOL alive;
@property (readonly, getter=isMouseActiveInPopup) BOOL mouseActiveInPopup;
@property (readonly, getter=isMouseInPopup) BOOL mouseInPopup;
@property CGFloat popupSize;
@property NSTimeInterval cancelTimeInterval;
@property CGFloat boxDistance;
@property CGFloat boxNubsideDistance;
@property BOOL popupUnder;
@property BOOL nubless;
@property NSTimeInterval actionRunDelay;
@property (readonly) NSConditionLock *lock;
@property NSRect lastClickedButtonFrame;


+ (Class)windowClass;
- (void)cancelPopup:(BOOL)quick;
- (void)cancelPopup;
- (void)cancelTip;
- (void)prepareNew;
- (void)doPopupWithButtons:(NSArray *)buttons location:(NSPoint)location keyboardMode:(BOOL)kbmode activeButton:(NMPopupWindowButton *)presetActiveButton;
- (void)doPopupWithButtons:(NSArray *)buttons location:(NSPoint)location;
- (void)doPopupWithButtons:(NSArray *)buttons;
- (void)startBoxDetect;
- (void)stopBoxDetect;
- (void)checkBoxWithPoint:(NSPoint)point;
- (NMPopupWindowButton *)newButtonWithTitle:(NSString *)title image:(NSImage *)image cancels:(BOOL)cancels targetBlock:(NMBasicBlock)block;
- (NMPopupWindowButton *)newButtonWithTitle:(NSString *)title image:(NSImage *)image targetBlock:(NMBasicBlock)block;
@end
