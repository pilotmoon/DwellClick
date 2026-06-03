// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
@class NMStatusBubbleWindow;

@interface DCWelcomeWindowController : NSObject <NSWindowDelegate> {
    NSArray *topLevelObjects;
    IBOutlet NSButton *startupSetting;

	IBOutlet NSView *waitView;
	IBOutlet NSView *welcomeView;
	IBOutlet NSView *axWarningView;
	IBOutlet NSView *axViewMav;
    IBOutlet NSView *axView2Mav;
	IBOutlet NSView *axViewDone;
	IBOutlet NSView *tutorialView;
	
	IBOutlet NSProgressIndicator *progress;
	BOOL waiting;

	BOOL isTryingToTurnOnAx;
	
	__strong id noteObj;
	
	NMStatusBubbleWindow *window;
	NSNib *nib;
}
@property (assign) BOOL waiting;
@property (readwrite) BOOL isTryingToTurnOnAx;
@property (readonly) NMStatusBubbleWindow *window;
- (IBAction)handleButton:(id)sender;
- (void)doLoading;
- (void)doWelcome;
- (void)doWarning;
- (void)doAX;
- (void)doTutorial;

@end
