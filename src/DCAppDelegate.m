// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCAppDelegate.h"
#import "DCAppDelegate+Distribution.h"
#import "DCAppDelegate+Startup.h"

#import "DCClicksPanelController.h"
#import "DCConstants.h"
#import "DCEngine.h"
#import "DCEngine+Gubbins.h"

#import "BundleIdentifierTransformer.h"
#import "ActionNameTransformer.h"
#import "ActionIconTransformer.h"
#import "SecondsTransformer.h"
#import "BundleIdIconTransformer.h"

#import "DCApp.h"
#import "DCUtils.h"
#import "DCLinks.h"

#import "NMKit/NMKit.h"

// private methods
@interface DCAppDelegate ()
- (void)doHousekeeping;
- (void)doFastHousekeeping;
@end

// Standard Cocoa Application Delegate.
@implementation DCAppDelegate
@synthesize engine, welcomeWindowController;

#pragma mark Initialisation

// Initializes application with factory defaults.
+ (void)initialize
{
	if (self == [DCAppDelegate class]) // standard check to prevent multiple runs
    {
		srandomdev();
        
#ifdef DEBUG_BUILD
        if (![[NSUserDefaults standardUserDefaults] objectForKey:kNMLogLevel]) {
            [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:kNMLogLevel];
        }
#endif
        
        CFBridgingRetain([NMStatusItemController sharedInstance]);
        
        DCPurpleColor=[NSColor colorWithDeviceRed:0.58 green:0.19 blue:0.78 alpha:1.0];
		
		NSData *animationColorData=[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:0.7411 green:0 blue:0.7411 alpha:1.0]];
        NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										 @NO, DCPrefsAutoClickOn,
										 @0.6f, DCPrefsDwellTimeSeconds,
										 [NSNumber numberWithFloat:DCDefaultMoveDistancePixels], DCPrefsMoveDistancePixels,
										 [NSNumber numberWithFloat:DCDefaultDwellDistancePixels], DCPrefsDwellDistancePixels,
										 @3.0f, DCPrefsSensitivitySetting,
										 @0, DCPrefsDefaultClick,
										 @0, DCPrefsPreventClickWhenOneFingerOnPad,
										 @0, DCPrefsPreventDragReleaseWhenOneFingerOnPad,
                                         @NO, DCPrefsAlwaysLockDrag,
                                         @YES, DCPrefsModifiersOn,
                                         @NO, DCPrefsFloatOnTop,
                                         @YES, DCPrefsEnableTablet,
										 @1.0f, DCPrefsActivationInterval,
                                         @YES, DCPrefsStatusItemHover,
                                         
										 @YES, DCPrefsSoundsOn,
										 @0.5f, DCPrefsSoundsVolume,
										 @YES, DCPrefsAnimationOn,
										 @YES, DCPrefsSymbolsOn,
										 @YES, DCPrefsAnimationCountdownOn,
										 @YES, DCPrefsAutoDragOn,
										 
										 @0, DCPrefsApplicationFilterType,
										 @YES, DCPrefsApplicationFilterBlockAll,
										 @[], DCPrefsApplicationList,
                                         
                                         [NSArray arrayWithConfigName:@"DefaultPanelClicks"], DCPrefsClicksPanelClicks,
										 @NO, DCPrefsClicksPanelShown,
										 @YES, DCPrefsClicksPanelShowLockButton,
                                         @0.9f, DCPrefsClicksPanelOpacity,
                                         @0.33f, DCPrefsClicksPanelSize,                                         
                                         @0, DCPrefsClicksPanelStyle,
                                         @2.0f, DCPrefsClicksPanelFadeInterval,                                                                              
										 
										 animationColorData, DCPrefsAnimationColor,
										 @0.20f, DCPrefsAnimationSize,
										 
										 @"Click 1", DCPrefsSoundsClick,
										 @"Default", DCPrefsSoundsDragDrop,
										 
										 @0ULL, DCPrefsClickCountDwell,
										 @0ULL, DCPrefsClickCountManual,
										 @YES, DCPrefsClickCountOn,
										 
										 @0.75f, DCPrefsQuickDragInterval,
										 @NO, DCPrefsQuickDragOn,
										 @NO, DCPrefsPopupsUnderneath,
										 @0.33f, DCPrefsPopupsSize,
                                         
										 /* hidden prefs */
                                         @(0.4), NMPrefsInitialAlpha,
                                         @(0.9), NMPrefsFullAlpha,
                                         
                                         @(YES), @"ClassicStyle",
                                         
										 NULL];
        

		
		// Register defaults
		NMLogInfo(@"Defaults: %@", defaults);
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		
		// register the value transformers
		[NSValueTransformer setValueTransformer:[[BundleIdentifierTransformer alloc] init] forName:@"BundleIdentifierTransformer"];
		[NSValueTransformer setValueTransformer:[[BundleIdIconTransformer alloc] init] forName:@"BundleIdIconTransformer"];
		[NSValueTransformer setValueTransformer:[[ActionNameTransformer alloc] init] forName:@"ActionNameTransformer"];
		[NSValueTransformer setValueTransformer:[[ActionIconTransformer alloc] init] forName:@"ActionIconTransformer"];
		[NSValueTransformer setValueTransformer:[[SecondsTransformer alloc] init] forName:@"SecondsTransformer"];
        
        // set legacy mode for popup images
        [NMPopupWindowButton setLegacyMode:YES];
    }
}

// Initialise members.
- (id)init
{
	if(!(self=[super init])) return nil;
	
	if([DCAppDelegate isAlreadyRunning]||[DCAppDelegate isBetaExpired])
	{
		quitting=YES;
		[NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.001]; 
	}
	else
	{
		[self distributionInit];
        
        slowHousekeepingMonitor=[NMUniversalMonitor housekeepingMonitorWithImmediateRun:NO
                                                                                repeats:1
                                                                               interval:15
                                                                                  block:^{
                                                                                      [self doHousekeeping];
                                                                                  }];

        [self doFastHousekeeping];
        fastHousekeepingMonitor=[NMUniversalMonitor fastHousekeepingMonitorWithBlock:^{
                                                                                      [self doFastHousekeeping];
                                                                                  }];
        
        firstRun=[self testFirstRun];
		versionUpgrade = [self testVersionUpgraded];
		
		// act on results
		if (firstRun) {
			NMLogInfo(@"This is the first run.");
			[self distributionFirstRun];
			[self showWelcomeWindow:self];
		}			
		else if (versionUpgrade) {
            [self distributionVersionUpgrade];
			NMLogInfo(@"Version was upgraded to %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
		}
		
		// Set up click engine.
		engine=[DCEngine sharedInstance];
		engine.delegate=self;
        engine.lastClickedPid=0;
		
		[engine addObserver:self forKeyPath:@"override" options:0 context:0];
        
        CFBridgingRetain([[NSNotificationCenter defaultCenter] addObserverForName:NMStatusItemClickedNotification 
                                                                   object:nil
                                                                    queue:nil
                                                               usingBlock:^(NSNotification *note) {
                                                                   if(engine.override) {
                                                                       [NSApp activateIgnoringOtherApps:YES];
                                                                       [welcomeWindowController.window bringAttentionToWindow];
                                                                   }
                                                                   if (engine.mouseInActivationArea) {
                                                                       engine.mouseInActivationArea=NO;
                                                                   }
                                                               }]);        
	}
	
	return self;
}

#pragma mark Custom Methods

- (void)doHousekeeping // timer method
{
	[engine saveClickCounts];
}

- (void)doFastHousekeeping // timer method
{
	[[NMUniversalAccessHelper sharedInstance] refreshState];
}

- (void)engineDidClick
{
	[self distributionDidClick];
}

#pragma mark Window manipulation

- (void)loadPrefsWindow
{
	if (!prefsController) {
        prefsController = [[DCPrefsController alloc] init];   
	}
}

- (IBAction)showPreferences:(id)sender
{
    [self loadPrefsWindow];
	if (aboutController) {
		[aboutController closeAboutWindow:self];
	}
	[NSApp activateIgnoringOtherApps:YES];
	[prefsController showWindow:self];
}

- (IBAction)showWelcomeWindow:(id)sender
{
	NMLogInfo(@"Showing welcome window.");
	if (!welcomeWindowController) {
        welcomeWindowController = [[DCWelcomeWindowController alloc] init];        
    }
	[welcomeWindowController doLoading];
}

#pragma mark App Delegate Methods

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	if (quitting) {
		return;
	}
	NMLogInfo(@"Application will finish launching.");
	
	[self distributionWillFinishLaunching];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	if (quitting) {
		return;
	}
	NMLogInfo(@"Application did finish launching.");
	[self doUI];
}

- (void)doUI
{
    NMRunAsyncOnMainThreadWithDelay(0.75, ^{ // delay to give things a chance to settle
		[engine start];
		
		[[NMStatusItemController sharedInstance] setReady:YES];
		if (firstRun) {
			[welcomeWindowController doWelcome];
		}
		
		[self distributionDidFinishLaunching];
        
        clicksPanelController = [[DCClicksPanelController alloc] init];
	});
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	NMLogInfo(@"Application will terminate.");
	[engine saveClickCounts];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	NMLogInfo(@"REOPEN");
    [[NMStatusItemController sharedInstance] setIconVisible:YES];
	[[NMStatusItemController sharedInstance] showAttachedMenu];
	return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object==engine && [keyPath isEqualToString:@"override"]) {
        [NMStatusItemController sharedInstance].override=engine.override;
	}
}

- (void)warnAX
{
	if (!welcomeWindowController) {
        welcomeWindowController = [[DCWelcomeWindowController alloc] init];        
    }
	[welcomeWindowController doWarning];
}


- (void)needsAX
{
	if (!welcomeWindowController) {
        welcomeWindowController = [[DCWelcomeWindowController alloc] init];        
    }
	[welcomeWindowController doAX];
}

- (void)needsTutorial
{
	if (!welcomeWindowController) {
        welcomeWindowController = [[DCWelcomeWindowController alloc] init];        
    }
	[welcomeWindowController doTutorial];
	
}

- (IBAction)showAbout:(id)sender
{
	NMLogInfo(@"show about");
	if (!aboutController) {
        aboutController = [[FCAboutController alloc] init];        
    }
	[aboutController showWindow:self];
}



@end
