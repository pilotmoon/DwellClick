// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

// controllers
#import "DCMouseTap.h"
#import "DCMouseClicker.h"
#import "DCDwellMachine.h"
#import "DCClickMachine.h"
#import "DCAnimationController.h"
#import "DCClickIntelligence.h"
#import "DCPopupsController.h"
#import "NMKit/NMStatusItemController.h"
#import "DCSymbolController.h"
#import "DCModifierController.h"

// selection options
#define SELECTION_OPTION_AUTO_DRAG (1<<1)
#define SELECTION_OPTION_DEFER_DROP (1<<5)
#define SELECTION_OPTION_MODIFIED_CONTROL (1<<6)
#define SELECTION_OPTION_MODIFIED_OPTION (1<<7)
#define SELECTION_OPTION_MODIFIED_COMMAND (1<<8)
#define SELECTION_OPTION_MODIFIED_SHIFT (1<<9)
#define SELECTION_OPTION_PANEL_CLICK (1<<12)

#define ALL_MODIFIER_OPTIONS (SELECTION_OPTION_MODIFIED_COMMAND|SELECTION_OPTION_MODIFIED_CONTROL|SELECTION_OPTION_MODIFIED_OPTION|SELECTION_OPTION_MODIFIED_SHIFT)

// global clicks
extern DCClick *DCClickNoClick;
extern DCClick *DCClickSingleClick;
extern DCClick *DCClickDrag;
extern DCClick *DCClickHeldDrag;
extern DCClick *DCClickPopup;
extern DCClick *DCClickDenied;
extern DCClick *DCClickAutoDragClick;
extern DCClick *DCClickQuickDrag;
extern DCClick *DCClickAbandonDrag;
extern DCClick *DCClickMouseUp;
extern DCClick *DCClickPopupButtonClick;
extern DCClick *DCClickPanelButtonClick;

// global tap data
extern DCMouseTap *DCTapData;

// animation control
extern NSUInteger *DCAnimationPosition;
extern NSUInteger *DCAnimationHide;

@interface DCEngine : NSObject <DCSelectionGroupDelegate> {
    // delegate is app delegate
	id __strong delegate;
    
    // all clicks and actions
	NSDictionary *clictionary;

    // controllers
	DCPopupsController *popupsController;
	DCAnimationController *animWindowController;
	DCSymbolController *symbolController;
	DCMouseTap *tap;
	DCDwellMachine *dwellMachine;
	DCClickMachine *clickMachine;
	DCClickIntelligence *intel;
    DCModifierController *modifierController;
    
	DCClick *previousClick;
	BOOL lockCurrentClick;
    BOOL holdDrag;
    BOOL lockModifier;
    BOOL mouseInPanel;
    BOOL mouseInActivationArea;
	NSTimer *activationTimer;
    
	DCClickEvent *lastDragStartEvent;
	DCClickEvent *lastSingleClickEvent;
	
	// set YES to temporarily suspend clicking during onboarding or modal flows
	BOOL override;

	unsigned long long dwellClickCount;
	unsigned long long manualClickCount;
	BOOL ignoreCount;
	
	BOOL hasDwelled;
    BOOL hasMovedSinceAction;
	CGEventFlags modifiersDown;
	CGEventFlags actedOnModifier;
	BOOL pendingFnPopup;
    
    BOOL gotShortcut;
    
    pid_t _lastClickedPid;
}

// the delegate (which is the app delegate)
@property (strong) id delegate;

// helper objects
@property (readonly) DCMouseTap *tap;
@property (readonly) DCDwellMachine *dwellMachine;
@property (readonly) DCClickMachine *clickMachine;
@property (readonly) NSDictionary *clictionary;
@property (readonly) DCClickIntelligence *intel;
@property (readonly) DCPopupsController *popupsController; 

@property (readonly) DCClick *defaultClick;
@property (assign) BOOL mouseInPanel;
@property (assign) BOOL mouseInActivationArea;
@property (assign) BOOL lockCurrentClick;
@property (assign) BOOL lockModifier;
@property (assign) BOOL holdDrag;
@property (assign) BOOL override;
@property (readonly) BOOL isDwellDetecting;
@property (readonly) CGEventFlags modifiersDown;
@property (readonly) DCModifierController *modifierController;
@property (readwrite) pid_t lastClickedPid;

// click counts
@property (readonly) unsigned long long dwellClickCount;
@property (readonly) unsigned long long manualClickCount;

// notification that event completed
- (void)eventIsComplete:(DCClickEvent *)event;

// trigger actions
- (void)fnKeyAction;
- (void)toggleDrag;
- (void)toggleHeldDrag;

- (void)draggingSameButtonDown;
- (void)draggingOtherButtonDown;
- (BOOL)escKeyPressed;

- (void)moveDetected;
- (void)dwellDetected;
- (void)restDetected;

- (void)activityDetected:(DCTapActivity)activity;
- (void)activityDetectedSinceRest:(DCTapActivity)activity;
- (void)dragWasLocked;

- (BOOL)modifierButtonDown:(CGEventFlags)flag;
- (BOOL)modifierButtonUp:(CGEventFlags)flag;
- (BOOL)modifierButtonPressed:(CGEventFlags)flag;

- (void)popupWillAppear;
- (BOOL)consumePendingFnPopup;

// quick drag
- (void)didQuickDragWithEvent:(DCClickEvent *)event;
- (BOOL)modifierKeyActionIsAllowed;
- (BOOL)fnKeyActionIsAllowed;

// singleton accessor and start method
+ (DCEngine *)sharedInstance;
- (void)start;

- (void)turnDwellClickOnFromPanel;

@end
