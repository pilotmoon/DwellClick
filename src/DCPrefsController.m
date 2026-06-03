// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCPrefsController.h"
#import "DCClickMachine.h"
#import "DCShortcutViewItem.h"
#import "DCConstants.h"
#import "DCAppDelegate.h"
#import "DCUtils.h"
#import "DCLinks.h"
#import "NMKit/NMKit.h"
#import <objc/runtime.h>

#define PREFS_RECENT_PANEL @"PrefsLastUsedPanel"

// Standard window controller subclass for Preferences window
@implementation DCPrefsController

- (BOOL)showWarning
{
	return NO;
}

- (DCEngine *)engine
{
	return [DCEngine sharedInstance];
}

- (NSString *)lastClickedAppId
{
    return NMBundleIdForPID([DCEngine sharedInstance].lastClickedPid);
}

+ (NSSet *)keyPathsForValuesAffectingLastClickedAppId
{
    return [NSSet setWithObject:@"engine.lastClickedPid"];
}

- (IBAction)resetAdjustments:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setFloat:DCDefaultMoveDistancePixels forKey:DCPrefsMoveDistancePixels];
    [[NSUserDefaults standardUserDefaults] setFloat:DCDefaultDwellDistancePixels forKey:DCPrefsDwellDistancePixels];
}

- (void)showWindow:(id)sender
{
	[[self window] center];
	[super showWindow:sender];
}

#pragma mark Shortcuts stuff

+ (NSArray *)shortcutIdentifiers
{
    return [NSArray arrayWithConfigName:@"ShortcutsList"];
}

+ (NSArray *)shortcutPrefsIdentifiers
{
    return [[self shortcutIdentifiers] mappedArrayUsingBlock:^id (id obj) {
        return [self prefsKeyForShortcutIdentifier:obj];
    }];
}


static NSString *const DCShortcutPrefix=@"DCShortcut.";

+ (NSString *)prefsKeyForShortcutIdentifier:(NSString *)key
{
    return key?[DCShortcutPrefix stringByAppendingString:key]:nil;
}

+ (NSString *)shortcutIdentifierRemovePrefix:(NSString *)key
{
    if ([key hasPrefix:DCShortcutPrefix]) {
        return [key substringFromIndex:[DCShortcutPrefix length]];
    }
    return nil;
}

+ (BOOL)keyIsFKey:(unsigned short)keyCode
{
    // allow unmodified F keys
    switch (keyCode) {
        case kVK_F1:
        case kVK_F2:
        case kVK_F3:
        case kVK_F4:
        case kVK_F5:
        case kVK_F6:
        case kVK_F7:
        case kVK_F8:
        case kVK_F9:
        case kVK_F10:
        case kVK_F11:
        case kVK_F12:
        case kVK_F13:
        case kVK_F14:
        case kVK_F15:
        case kVK_F16:
        case kVK_F17:
        case kVK_F18:
        case kVK_F19:
        case kVK_F20:
            return YES;
        default:
            return NO;
    }
}

- (BOOL)recorderControl:(SRRecorderControl *)recorder canRecordShortcut:(SRShortcut *)shortcut
{
    // get set of all shortcuts, excluding the current shortcut for the current key
    NSSet *others=[[[self class] shortcutPrefsIdentifiers] collectSet:^SRShortcut *(NSString *k) {
        NSString *identifier=objc_getAssociatedObject(recorder, @selector(setUpShortcuts));

        if ([k isEqualToString:identifier]) {
            return nil;
        }
        NSDictionary *rep=[[NSUserDefaults standardUserDefaults] dictionaryForKey:k];
        return [rep isKindOfClass:[NSDictionary class]]?[SRShortcut shortcutWithDictionary:rep]:nil;
    }];
    return ![others containsObject:shortcut];
}

- (BOOL)recorderControl:(SRRecorderControl *)recorder shouldUnconditionallyAllowModifierFlags:(NSEventModifierFlags)modifierFlags forKeyCode:(SRKeyCode)keyCode
{
    return [[self class] keyIsFKey:keyCode];
}

- (void)setUpShortcuts
{
    // setting the content populates the collection view with shortcut view items
	[shortcutsView setContent:[[self class] shortcutIdentifiers]];
	
    // go through creating recorder controls and binding to prefs
	[[[self class] shortcutPrefsIdentifiers] enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        // create recorder control
        SRRecorderControl *recorderControl=[[SRRecorderControl alloc] initWithFrame:NSMakeRect(220, 0, 145, 25)];
        objc_setAssociatedObject(recorderControl, @selector(setUpShortcuts), key, OBJC_ASSOCIATION_COPY);
        [recorderControl setAutoresizingMask:NSViewMinXMargin];
        [recorderControl setDelegate:self];
        [recorderControl bind:NSValueBinding
                     toObject:[NSUserDefaultsController sharedUserDefaultsController]
                  withKeyPath:[@"values." stringByAppendingString:key]
                      options:nil];

        // add shortcut to view
        NSCollectionViewItem *item=[shortcutsView itemAtIndex:idx];
        [[item view] addSubview:recorderControl];
    }];
}

#pragma mark ...

- (void)changePanes:(id)sender
{
	NSString *identifier=[[tabView tabViewItemAtIndex:[sender tag]] identifier];
	NMLogInfo(@"ID %@", identifier);
	[tabView selectTabViewItemWithIdentifier:identifier];
	[[NSUserDefaults standardUserDefaults] setObject:identifier forKey:PREFS_RECENT_PANEL];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *toolbarItem=[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	NSDictionary *d=panels[itemIdentifier];
	NSString *itemLabel=d[@"title"];
	[toolbarItem setLabel:itemLabel];
	[toolbarItem setTag:[tabView indexOfTabViewItemWithIdentifier:itemIdentifier]];
	[toolbarItem setToolTip:itemLabel];
	[toolbarItem setImage:[NSImage imageNamed:itemIdentifier]];
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector(changePanes:)];
	NMLogInfo(@"tbi %@", toolbarItem);
	return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return @[];
}
	 
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [panels allKeys];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [panels allKeys];
}

- (void)setUpTabs
{
	if ([[toolbar items] count]==0) {
		[(NSArray *)@[@"prefs-Clicking", @"prefs-Feedback",
                     @"prefs-Popups", @"prefs-Panel",
                     @"prefs-Apps", @"prefs-Keyboard",
                     @"prefs-Advanced", @"prefs-Software"]
		 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			 [toolbar insertItemWithItemIdentifier:obj atIndex:idx];	
		 }];		
	}
	[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
}

- (void)hookUpNib
{	
	// load nib
	nib=[[NSNib alloc] initWithNibNamed:@"Prefs" bundle:nil];
    NSArray *tloTemp=nil;
    [nib instantiateWithOwner:self topLevelObjects:&tloTemp];
    topLevelObjects=tloTemp;
	
	panels=@{@"prefs-General": [NSMutableDictionary dictionaryWithObjectsAndKeys:
		 generalView, @"view",
		 @"General", @"title",
		 nil],
		
		@"prefs-Clicking": [NSMutableDictionary dictionaryWithObjectsAndKeys:
		 clickingView, @"view",
		 @"Clicking", @"title",
		 nil],
		
		@"prefs-Feedback": [NSMutableDictionary dictionaryWithObjectsAndKeys:
		 feedbackView, @"view",
		 @"Feedback", @"title",
		 nil],
		
		@"prefs-Popups": [NSMutableDictionary dictionaryWithObjectsAndKeys:
		 [popupsPrefsController view], @"view",
		 @"Pop-up", @"title",
		 nil],
		
        @"prefs-Panel": [NSMutableDictionary dictionaryWithObjectsAndKeys:
         [panelPrefsController view], @"view",
         @"Panel", @"title",
         nil],
        
        @"prefs-Apps": [NSMutableDictionary dictionaryWithObjectsAndKeys:
		 smartView, @"view",
		 @"Apps", @"title",
		 nil],
			  
		@"prefs-Keyboard": [NSMutableDictionary dictionaryWithObjectsAndKeys:
		 keyboardView, @"view",
		 @"Keyboard", @"title",
		 nil],
		
		@"prefs-Advanced": [NSMutableDictionary dictionaryWithObjectsAndKeys:
		 advancedView, @"view",
		 @"Advanced", @"title",
		 nil],
		
		@"prefs-Software": [NSMutableDictionary dictionaryWithObjectsAndKeys:
		 [softwareController view], @"view",
		 @"Software", @"title",
		 nil]};

	// set up toolbar
	toolbar = [(NSToolbar *)[NSToolbar alloc] initWithIdentifier:@"PrefsToolbar"];
	[toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[toolbar setDelegate:self];
	[[self window] setToolbar:toolbar];
    [[self window] setToolbarStyle:NSWindowToolbarStylePreference];
	
	// set up all the panels in the tab view
	for(NSString *k in [panels allKeys])
	{
		NSMutableDictionary *d=panels[k];
		NSTabViewItem *item=[(NSTabViewItem *)[NSTabViewItem alloc] initWithIdentifier:k];
		NSView *v=d[@"view"];
		[item setView:v];
		[item setLabel:d[@"title"]];
		d[@"tabViewItem"] = item;
		d[@"panelHeight"] = [NSNumber numberWithFloat:[v frame].size.height];
		[tabView addTabViewItem:item];
	}
	[self setUpTabs];
	
	// Select the preferences page the user last had selected when this window was opened:
	NSString *lastPrefsIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:PREFS_RECENT_PANEL];
	if(!lastPrefsIdentifier) {
        lastPrefsIdentifier=@"prefs-Clicking";
    }
        
    [tabView selectTabViewItemWithIdentifier:lastPrefsIdentifier];
    [toolbar setSelectedItemIdentifier:lastPrefsIdentifier];

		
	// load shortcuts and set initial value
	[self setUpShortcuts];
}


// Returns instance initialized with "Prefs" nib.
- (id) init {	
	// make window
	NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 500, 500)
                                                 styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable
												   backing:NSBackingStoreBuffered
													 defer:NO];
	[window setTitle:@"DwellClick Preferences"];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsFloatOnTop]) {
        [window setLevel:NSFloatingWindowLevel];
    }
	[self setWindow:window];
	tabView=[[NSTabView alloc] initWithFrame:[(NSView *)[window contentView] frame]];
	[tabView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
	[tabView setTabViewType:NSNoTabsNoBorder];
	[tabView setDelegate:self];
	[[window contentView] addSubview:tabView];
	
	// set up pane controllers
	softwareController=[[DCPrefsSoftwareController alloc] init];
	softwareController.prefsController=self;
	popupsPrefsController=[[DCPrefsPopupsController alloc] init];
	popupsPrefsController.prefsController=self;
	panelPrefsController=[[DCPrefsPanelController alloc] init];
	panelPrefsController.prefsController=self;
	
    // profs to observe
	[self observePrefsKey:DCPrefsSensitivitySetting];
	[self observePrefsKey:DCPrefsClicksPanelEnabled];
	
	// sounds names for arrays
	clickSoundNames=[NSMutableArray arrayWithObject:DCSoundNoSoundName];
	[(NSMutableArray *)clickSoundNames addObjectsFromArray:((NSDictionary *)[NSDictionary dictionaryWithContentsOfFile:
					  [[NSBundle mainBundle] pathForResource:@"Sounds" ofType:@"plist"]])[@"ClickSounds"]];
	dragDropSoundNames=[NSMutableArray arrayWithObjects:DCSoundNoSoundName,@"(same as click)",nil];
	[(NSMutableArray *)dragDropSoundNames addObjectsFromArray:((NSDictionary *)[NSDictionary dictionaryWithContentsOfFile:
																[[NSBundle mainBundle] pathForResource:@"Sounds" ofType:@"plist"]])[@"DragDropSounds"]];

	[self hookUpNib];
    return self;
}

- (void)setWindowContentHeight:(CGFloat)height
{
	// get the window frame
	NSRect oldRect=[self.window frame];
	NSRect windowFrame=[NSWindow contentRectForFrameRect:oldRect
											   styleMask:[self.window styleMask]];

	
	// get toolbar height
	CGFloat toolbarHeight=0.0;
    if([toolbar isVisible]) {
        toolbarHeight = NSHeight(windowFrame)- NSHeight([(NSView *)[[self window] contentView] frame]);
    }
	
	// calculate new height
	CGFloat diff=height+toolbarHeight-windowFrame.size.height;
	windowFrame.size.height+=diff;
	windowFrame.origin.y-=diff;
	
	// get the new rect
	NSWindow *window=[self window];
	NSRect newRect=[NSWindow frameRectForContentRect:windowFrame styleMask:[window styleMask]];
	
	// resize the window
	if ([window isVisible]) {
		NMRunAsyncOnMainThread(^{
			[window setFrame:newRect display:YES animate:YES];
		});
	}
	else {
		[window setFrame:newRect display:NO animate:NO];
	}
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NMLogInfo(@"did select %@", [tabViewItem identifier]);
	NSDictionary *d=panels[[tabViewItem identifier]];

	// get height according to whether simple or advanced
	CGFloat hfloat=[d[@"panelHeight"] floatValue];

	// hide views below the line
	NSView *pView=d[@"view"];
	[[pView subviews] enumerateObjectsUsingBlock:^(NSView *view, NSUInteger idx, BOOL *stop) {
		CGFloat y=NSMaxY([pView frame])-NSMinY([view frame]);
		[view setHidden:y>hfloat];
	}];
	

	[self setWindowContentHeight:hfloat];	
}

#pragma mark Apps Panel

- (IBAction)addApplication:(id)sender
{
    NSString *active=nil;
    if ([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagOption) {
        active=[self lastClickedAppId];
    }
    
    if (active) {            
        NSDictionary *entry=@{@"bundleId": active};
        if(![applicationsController.arrangedObjects containsObject:entry])
        {
            [applicationsController addObject:entry];		
        }
    }
    else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES);
        if ([paths count]==0) return;
        
        NSOpenPanel *op=[NSOpenPanel openPanel];
        [op setPrompt:@"Add"];
        [op setAllowsMultipleSelection:YES];
        [op setAllowedFileTypes:@[@"app"]];
        [op setDirectoryURL:[NSURL fileURLWithPath:paths[0]]];
        [op beginSheetModalForWindow:self.window completionHandler:^(NSInteger code) {
            if (code == NSOKButton)
            {
                NMLogInfo(@"OK!!");
                if ([[op URLs] count]>0)
                {
                    for(NSURL *url in [op URLs])
                    {
                        NSString *bundleId=[[NSBundle bundleWithPath:[url path]] bundleIdentifier];
                        if (bundleId)
                        {
                            if ([bundleId isEqualToString:DCProductID()])
                            {
                                NSRunAlertPanel(@"Cannot Add Application",
                                                @"DwellClick itself cannot be added to the application list.",
                                                nil, nil, nil);
                            }
                            else
                            {
                                NSDictionary *entry=@{@"bundleId": bundleId};
                                if(![applicationsController.arrangedObjects containsObject:entry])
                                {
                                    NMLogInfo(@"adding %@", entry);
                                    [applicationsController addObject:entry];		
                                }
                            }
                        }
                    }
                }
            }
        }];
    }
}



- (NSArray *)appFilterOptions
{
	return @[@"Don't", @"Only"];
}

// Sensitivity setting
/*
 http://www.arachnoid.com/polysolve/index.html
 */
- (void)setSensitivity:(float)x
{
	// input x: -2 to 5;
	float time;
	if (x>=0) {
		x=4-x;
		time=0.845-0.265*x+0.025*x*x;
	}
	else {
		time=0.185+0.1*x;
	}
	NMLogInfo(@"setting time %f", time);
	[[NSUserDefaults standardUserDefaults] setFloat:time forKey:DCPrefsDwellTimeSeconds];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath hasSuffix:DCPrefsSensitivitySetting]) {
		[self setSensitivity:[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsSensitivitySetting]];
	}
}

- (IBAction)getHelp:(id)sender
{
	NSInteger tag=[sender tag];
	NSString *topic=nil;
	switch (tag) {
		case 0:
			topic=@"prefs-software";
			break;
		case 1:
			topic=@"prefs-clicking";
			break;
		case 2:
			topic=@"prefs-general";
			break;
		case 3:
			topic=@"prefs-feedback";
			break;
		case 4:
			topic=@"prefs-popup";
			break;
		case 5:
			topic=@"prefs-apps";
			break;
		case 6:
			topic=@"prefs-keyboard";
			break;
		case 7:
			topic=@"prefs-advanced";
			break;
		case 8:
			topic=@"prefs-panel";
			break;
        default:
			break;
	}
	if(topic) {
		[DCLinks openHelpTopic:topic];	
	}
	else {
		[DCLinks openHelpLink:self];
	}
}

@end
