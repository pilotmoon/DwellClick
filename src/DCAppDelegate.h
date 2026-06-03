// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

#import "DCMainMenuController.h"
#import "DCWelcomeWindowController.h"
#import "DCPrefsController.h"
#import "DCClicksPanelController.h"
#import "FCAboutController.h"
#import "DCApp.h"
#import "NMKit/NMStatusItemController.h"

@class DCEngine, NMUniversalMonitor, SPUStandardUpdaterController, SPUUpdater;

@interface DCAppDelegate : NSObject {
	// main menu
	IBOutlet DCMainMenuController *menuController;
    
    // panel
    DCClicksPanelController *clicksPanelController;

	// windows
	DCWelcomeWindowController *welcomeWindowController;	
	DCPrefsController *prefsController;
	FCAboutController *aboutController;
	
	// the engine
	DCEngine *engine;

	// other stuff
    NMUniversalMonitor *slowHousekeepingMonitor;
    NMUniversalMonitor *fastHousekeepingMonitor;
    SPUStandardUpdaterController *updaterController;
    
	BOOL firstRun;
	BOOL versionUpgrade;
	BOOL quitting;
}
@property (readonly) DCEngine *engine;
@property (readonly) DCWelcomeWindowController *welcomeWindowController;
@property (readonly) SPUStandardUpdaterController *updaterController;
@property (readonly) SPUUpdater *updater;

// show windows
- (IBAction)showPreferences:(id)sender;
- (IBAction)showWelcomeWindow:(id)sender;

// notification
- (void)engineDidClick;
- (void)warnAX;
- (void)needsAX;
- (void)needsTutorial;

- (IBAction)showAbout:(id)sender;

@end
