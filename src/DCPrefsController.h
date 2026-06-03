// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NSObject+NMObservePrefs.h"
#import "NMKit/NMConfigUtils.h"
#import "NSUserDefaults+Color.h"
#import "NSUserDefaults+Archive.h"
#import "DCEngine.h"
#import "DCPrefsSoftwareController.h"
#import "DCPrefsPopupsController.h"
#import "DCPrefsPanelController.h"
#import <ShortcutRecorder/SRRecorderControl.h>

@interface DCPrefsController : NSWindowController <NSTabViewDelegate, NSToolbarDelegate, SRRecorderControlDelegate>
{
    NSArray *topLevelObjects;
	NSNib *nib;
	NSTabView *tabView;
	NSToolbar *toolbar;
	NSDictionary *panels;

	NSArray *clickSoundNames;
	NSArray *dragDropSoundNames;
	
	IBOutlet NSCollectionView *shortcutsView;
	IBOutlet NSArrayController *applicationsController;
	
	IBOutlet NSView *generalView;
	IBOutlet NSView *feedbackView;
	IBOutlet NSView *clickingView;
	IBOutlet NSView *smartView;
	IBOutlet NSView *keyboardView;
	IBOutlet NSView *advancedView;
	
	DCPrefsSoftwareController *softwareController;
	DCPrefsPopupsController *popupsPrefsController;
	DCPrefsPanelController *panelPrefsController;
}
@property (readonly) BOOL showWarning;
@property (readonly) NSString *lastClickedAppId;
- (IBAction)addApplication:(id)sender;
- (IBAction)resetAdjustments:(id)sender;

- (void)setWindowContentHeight:(CGFloat)height;

- (IBAction)getHelp:(id)sender;

+ (BOOL)keyIsFKey:(unsigned short)keyCode;
+ (NSArray *)shortcutIdentifiers;
+ (NSArray *)shortcutPrefsIdentifiers;
+ (NSString *)prefsKeyForShortcutIdentifier:(NSString *)key;
+ (NSString *)shortcutIdentifierRemovePrefix:(NSString *)key;

@end
