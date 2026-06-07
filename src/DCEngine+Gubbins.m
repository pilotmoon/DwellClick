// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCEngine.h"
#import "DCEngine+Gubbins.h"

#import "DCAppDelegate.h"
#import "DCConstants.h"

#import "DCKeyedSelection.h"
#import "DCSimpleTrigger.h"

#import "DCSoundController.h"
#import "NMKit/NMKit.h"

#import "DCPrefsController.h"
#import <ShortcutRecorder/ShortcutRecorder.h>

@interface DCEngine()
@end

// for allocating clicks with no target
#define NIL_ALLOC(_nam_,_typ_,_drop_) \
 [[DCClick alloc] initWithTarget:nil\
 selector:nil\
 group:self.clickMachine\
 name:@#_nam_\
 type:_typ_\
 drop:_drop_]

#define ROOT_ALLOC(_nam_,_tgt_,_sel_,_typ_,_drop_) \
 [[DCClick alloc] initWithTarget:_tgt_\
 selector:@selector(_sel_:)\
 group:self.clickMachine\
 name:@#_nam_\
 type:_typ_\
 drop:_drop_]

#define ROOT(_nam_,_tgt_,_sel_,_typ_,_drop_) \
 [c setObject:ROOT_ALLOC(_nam_,_tgt_,_sel_,_typ_,_drop_) forKey:@#_nam_]

#define NILCLICK(_nam_,_typ_,_drop_) \
 [c setObject:NIL_ALLOC(_nam_,_typ_,_drop_) forKey:@#_nam_]

#define CLICK(_nam_,_tgt_,_sel_,_typ_) \
 ROOT(_nam_,_tgt_,_sel_,_typ_,nil)

#define FLAG(_nam_, _grp_, _flag_) \
 [c setObject:[[DCFlagSelection alloc] initWithName:@#_nam_ \
 mask:_flag_ \
 group:_grp_] \
 forKey:@#_nam_];

#define KEYED(_nam_, _obj_, _key_) \
 [c setObject:[[DCKeyedSelection alloc] initWithName:@#_nam_ \
 object:_obj_ \
 keyPath:@#_key_] forKey:@#_nam_];

#define TRIGGER(_nam_, _obj_, _sel_) \
 [c setObject:[[DCSimpleTrigger alloc] initWithName:@#_nam_ \
 target:_obj_ \
 selector:@selector(_sel_)] forKey:@#_nam_]; \

@implementation DCEngine (Gubbins)

- (id)init
{
	if (!(self=[super init])) {
		return nil;
	}
    
	if (![NMUniversalAccessHelper sharedInstance].axEnabled) {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:DCPrefsAutoClickOn];
	}
	// Click counter
	[self loadClickCounts];
	
	// Early instantiate singletons
	[DCSoundController sharedInstance];
	
	// Intelligence
	intel=[[DCClickIntelligence alloc] init];
	
	// Animation window
	animWindowController = [[DCAnimationController alloc] init];
	DCAnimationPosition = [animWindowController posPointer];
	DCAnimationHide = [animWindowController hidePointer];
	
	// Symbol controller
	symbolController = [[DCSymbolController alloc] initWithAnimationController:animWindowController];
	
	// Click machine
	clickMachine = [[DCClickMachine alloc] init];
	clickMachine.delegate=self;
	
	// Dwell machine and tap
	tap = [[DCMouseTap alloc] init];
	DCTapData=tap;
	dwellMachine = [[DCDwellMachine alloc] initWithTap:tap
											   monitor:tap
									   clickController:clickMachine];
	[tap setDelegate:dwellMachine];
	
	// Click Dictionary
	NSMutableDictionary *c = [NSMutableDictionary dictionary];
	clictionary = c;
	
	// No-Click
	c[[self.clickMachine noSelectionObject].name] = [self.clickMachine noSelectionObject];
	
    modifierController=[[DCModifierController alloc] init];
    
	// Left clicker workhorse
	DCMouseClicker *standardLeftClicker=[DCMouseClicker leftClickerWithModifierController:modifierController tap:tap];
	
	// Double and Triple
	CLICK(Double-Click, standardLeftClicker, doubleClickWithEvent, DCClickTypeDouble);
	CLICK(Triple-Click, standardLeftClicker, tripleClickWithEvent, DCClickTypeTriple);
	
	// Unmodified
	CLICK(Release, standardLeftClicker, dragEndWithEvent, DCClickTypeDragEnd);
	ROOT(Click, standardLeftClicker, clickWithEvent, DCClickTypeSingle, (DCClick *)[clictionary objectForKey:@"Release"]);
	ROOT(Drag, standardLeftClicker, dragBeginWithEvent, DCClickTypeDragBegin, (DCClick *)[clictionary objectForKey:@"Release"]);
    
	ROOT(HeldDrag, standardLeftClicker, dragBeginWithEvent, DCClickTypeDragBegin, (DCClick *)[clictionary objectForKey:@"Release"]);
	[(DCSelection *)clictionary[@"HeldDrag"] setOptions:SELECTION_OPTION_DEFER_DROP];
    
	// Nil clicks
	NILCLICK(Denied, DCClickTypeNone, nil);
        
    // Popup
	NILCLICK(Popup, DCClickTypeNone, nil);
	
	// abandon drag
	NILCLICK(Abandon-Drag, DCClickTypeDragEnd, nil);
	
	// A "begin drag" that doesn't press the mouse (used for quick drag)
	NILCLICK(Quick-Drag, DCClickTypeDragBegin, nil);
    
	// Mouse Up
	NILCLICK(Mouse-Up, DCClickTypeMouseUp, nil);
	
	// Popup Button Click
	ROOT(PopupButtonClick, standardLeftClicker, clickWithEvent, DCClickTypePopupButton, nil);

    // Panel Button Click
	ROOT(PanelButtonClick, standardLeftClicker, clickWithEvent, DCClickTypeSingle, nil);
	[(DCSelection *)clictionary[@"PanelButtonClick"] setOptions:SELECTION_OPTION_PANEL_CLICK];
	
	// Auto Drag
	CLICK(Auto-Release, standardLeftClicker, dragEndWithEvent, DCClickTypeDragEnd);
	ROOT(Auto-Drag, standardLeftClicker, dragBeginWithEvent, DCClickTypeDragBegin, (DCClick *)[clictionary objectForKey:@"Auto-Release"]);
	[(DCSelection *)clictionary[@"Auto-Drag"] setOptions:SELECTION_OPTION_AUTO_DRAG];
	[(DCSelection *)clictionary[@"Auto-Release"] setOptions:SELECTION_OPTION_AUTO_DRAG];
	
	// Modified Actions
	CLICK(Control-Release, standardLeftClicker, dragEndWithEvent, DCClickTypeDragEnd);
	ROOT(Control-Click, standardLeftClicker, clickWithEvent, DCClickTypeSingle, (DCClick *)[clictionary objectForKey:@"Control-Release"]);
	ROOT(Control-Drag, standardLeftClicker, dragBeginWithEvent, DCClickTypeDragBegin, (DCClick *)[clictionary objectForKey:@"Control-Release"]);
	[(DCSelection *)clictionary[@"Control-Click"] setOptions:SELECTION_OPTION_MODIFIED_CONTROL];
	[(DCSelection *)clictionary[@"Control-Drag"] setOptions:SELECTION_OPTION_MODIFIED_CONTROL];
	[(DCSelection *)clictionary[@"Control-Release"] setOptions:SELECTION_OPTION_MODIFIED_CONTROL];
	
	CLICK(Option-Release, standardLeftClicker, dragEndWithEvent, DCClickTypeDragEnd);
	ROOT(Option-Click, standardLeftClicker, clickWithEvent, DCClickTypeSingle, (DCClick *)[clictionary objectForKey:@"Option-Release"]);
	ROOT(Option-Drag, standardLeftClicker, dragBeginWithEvent, DCClickTypeDragBegin, (DCClick *)[clictionary objectForKey:@"Option-Release"]);
	[(DCSelection *)clictionary[@"Option-Click"] setOptions:SELECTION_OPTION_MODIFIED_OPTION];
	[(DCSelection *)clictionary[@"Option-Drag"] setOptions:SELECTION_OPTION_MODIFIED_OPTION];
	[(DCSelection *)clictionary[@"Option-Release"] setOptions:SELECTION_OPTION_MODIFIED_OPTION];
    
	
	CLICK(Command-Release, standardLeftClicker, dragEndWithEvent, DCClickTypeDragEnd);
	ROOT(Command-Click, standardLeftClicker, clickWithEvent, DCClickTypeSingle, (DCClick *)[clictionary objectForKey:@"Command-Release"]);
	ROOT(Command-Drag, standardLeftClicker, dragBeginWithEvent, DCClickTypeDragBegin, (DCClick *)[clictionary objectForKey:@"Command-Release"]);
	[(DCSelection *)clictionary[@"Command-Click"] setOptions:SELECTION_OPTION_MODIFIED_COMMAND];
	[(DCSelection *)clictionary[@"Command-Drag"] setOptions:SELECTION_OPTION_MODIFIED_COMMAND];
	[(DCSelection *)clictionary[@"Command-Release"] setOptions:SELECTION_OPTION_MODIFIED_COMMAND];
	
	CLICK(Shift-Release, standardLeftClicker, dragEndWithEvent, DCClickTypeDragEnd);
	ROOT(Shift-Click, standardLeftClicker, clickWithEvent, DCClickTypeSingle, (DCClick *)[clictionary objectForKey:@"Shift-Release"]);
	ROOT(Shift-Drag, standardLeftClicker, dragBeginWithEvent, DCClickTypeDragBegin, (DCClick *)[clictionary objectForKey:@"Shift-Release"]);
	[(DCSelection *)clictionary[@"Shift-Click"] setOptions:SELECTION_OPTION_MODIFIED_SHIFT];
	[(DCSelection *)clictionary[@"Shift-Drag"] setOptions:SELECTION_OPTION_MODIFIED_SHIFT];
	[(DCSelection *)clictionary[@"Shift-Release"] setOptions:SELECTION_OPTION_MODIFIED_SHIFT];
	
	DCClickNoClick=(DCClick *)[self.clickMachine noSelectionObject];
	DCClickDenied=(DCClick *)clictionary[@"Denied"];
	DCClickSingleClick=(DCClick *)clictionary[@"Click"];
	DCClickHeldDrag=(DCClick *)clictionary[@"HeldDrag"];
	DCClickDrag=(DCClick *)clictionary[@"Drag"];
	DCClickPopup=(DCClick *)clictionary[@"Popup"];
    
	DCClickAutoDragClick=(DCClick *)clictionary[@"Auto-Drag"];
	DCClickAbandonDrag=(DCClick *)clictionary[@"Abandon-Drag"];
	DCClickQuickDrag=(DCClick *)clictionary[@"Quick-Drag"];
    DCClickMouseUp=(DCClick *)clictionary[@"Mouse-Up"];
	DCClickPopupButtonClick=(DCClick *)clictionary[@"PopupButtonClick"];
	DCClickPanelButtonClick=(DCClick *)clictionary[@"PanelButtonClick"];
	
	// Bound selections
	KEYED(Lock, self, lockCurrentClick);
	KEYED(On-Off, self, dwellClickOn);
	
	// Triggers
	TRIGGER(Drag-Toggle, self, toggleDrag);
    TRIGGER(HeldDrag-Toggle, self, toggleHeldDrag);
	TRIGGER(FnEquiv, self, fnKeyAction);

    // Flags
    FLAG(ToggleControl, modifierController, kCGEventFlagMaskControl);
    FLAG(ToggleOption, modifierController, kCGEventFlagMaskAlternate);
    FLAG(ToggleShift, modifierController, kCGEventFlagMaskShift);
    FLAG(ToggleCommand, modifierController, kCGEventFlagMaskCommand);
	
	// Register for preferences change notifications.
	[self observePrefsKey:DCPrefsDwellTimeSeconds];
	[self observePrefsKey:DCPrefsDwellDistancePixels];
	[self observePrefsKey:DCPrefsMoveDistancePixels];
	[self observePrefsKey:DCPrefsAutoClickOn];
    
    NMObserveKeyUsingBlock(self, @"holdDrag", ^{
        if (self.holdDrag) {
            [self dragWasLocked];
        }
    });
    
	[[NMUniversalAccessHelper sharedInstance] addObserver:self forKeyPath:@"axEnabled" options:0 context:0];
    
	[self observePrefsKey:DCPrefsDefaultClick];
	[self addObserver:self forKeyPath:@"lockCurrentClick" options:0 context:nil];
    [self addObserver:self forKeyPath:@"currentModifier" options:0 context:nil];
	[self addObserver:self forKeyPath:@"mouseInPanel" options:0 context:nil];
	[self addObserver:self forKeyPath:@"mouseInActivationArea" options:0 context:nil];
    
	// Observe when selected click changes
	[clickMachine addObserver:self forKeyPath:@"selectedItem" options:0 context:nil];
	[clickMachine addObserver:self forKeyPath:@"dragging" options:0 context:nil];
	[modifierController addObserver:self forKeyPath:@"flags" options:0 context:nil];
    
	// List our clicks
	NMLogInfo(@"Clicks: %@", clictionary);
	
	// popups controller
	popupsController = [[DCPopupsController alloc] initWithClictionary:(NSDictionary *)clictionary];
	[popupsController bind:@"popupSize" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:DCPrefsPopupsSize options:0];
	[popupsController bind:@"popupUnder" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:DCPrefsPopupsUnderneath options:0];
	

    [self setupHotKeys];
    
	return self;
}

#pragma mark Hot Keys

- (void)setupHotKeys
{
    // set up observers
    for(NSString *identifier in [DCPrefsController shortcutIdentifiers])
    {
        NSString *prefsKey=[DCPrefsController prefsKeyForShortcutIdentifier:identifier];
        NMObservePrefsKeyUsingBlock(prefsKey, ^{
            [self processHotKeyChange:identifier];
        });
    }
}

- (void)registerHotKeys
{
	for(NSString *identifier in [DCPrefsController shortcutIdentifiers]) {
        [self processHotKeyChange:identifier];
	}
}

- (void)processHotKeyChange:(NSString *)identifier
{
    [self unregisterHotKeyWithIdentifier:identifier];
    if (self.dwellClickOn || [identifier isEqualToString:@"On-Off"]) {
        [self registerHotKeyWithIdentifier:identifier];
    }
}

- (void)unregisterHotKeyWithIdentifier:(NSString *)identifier
{
    NSString *const prefsKey=[DCPrefsController prefsKeyForShortcutIdentifier:identifier];

    NSArray *const actions=[[SRGlobalShortcutMonitor sharedMonitor] actionsForKeyEvent:SRKeyEventTypeDown];
    for (SRShortcutAction *action in actions) {
        if ([action.identifier isEqualToString:prefsKey]) {
            [[SRGlobalShortcutMonitor sharedMonitor] removeAction:action forKeyEvent:SRKeyEventTypeDown];
        }
    }
}

- (void)registerHotKeyWithIdentifier:(NSString *const)identifier
{
    NSString *const prefsKey=[DCPrefsController prefsKeyForShortcutIdentifier:identifier];
    
    NSDictionary *const dict=[[NSUserDefaults standardUserDefaults] dictionaryForKey:prefsKey];
	if ([dict isKindOfClass:[NSDictionary class]])
	{
        SRShortcut *const shortcut=[SRShortcut shortcutWithDictionary:dict];
        const id<DCTriggerable> trigger=(DCSelection *)clictionary[identifier];
        if (shortcut && trigger) {
            SRShortcutAction *const action=[SRShortcutAction shortcutActionWithShortcut:shortcut actionHandler:^BOOL(SRShortcutAction *anAction) {
                gotShortcut=YES;
                if (self.lockCurrentClick && !clickMachine.dragging) {
                    self.lockCurrentClick=NO;
                }
                [trigger performTriggeredActionFromKeyboard];
                return YES;
            }];
            action.identifier=prefsKey;
            [[SRGlobalShortcutMonitor sharedMonitor] addAction:action forKeyEvent:SRKeyEventTypeDown];
        }
    }
}

#pragma mark Click Counting

- (void)loadClickCounts
{
	[self willChangeValueForKey:@"dwellClickCount"];
	NSNumber *num=[[NSUserDefaults standardUserDefaults] objectForKey:DCPrefsClickCountDwell];
	dwellClickCount=[num isKindOfClass:[NSNumber class]]?[num unsignedLongLongValue]:0;
	[self didChangeValueForKey:@"dwellClickCount"];
	
	[self willChangeValueForKey:@"manualClickCount"];
	num=[[NSUserDefaults standardUserDefaults] objectForKey:DCPrefsClickCountManual];
	manualClickCount=[num isKindOfClass:[NSNumber class]]?[num unsignedLongLongValue]:0;
	[self didChangeValueForKey:@"manualClickCount"];
}

- (void)saveClickCounts
{
	[[NSUserDefaults standardUserDefaults] setObject:@(dwellClickCount) forKey:DCPrefsClickCountDwell];
	[[NSUserDefaults standardUserDefaults] setObject:@(manualClickCount) forKey:DCPrefsClickCountManual];
}

- (void)resetClickCounts
{
	[self willChangeValueForKey:@"dwellClickCount"];
	dwellClickCount=0;
	[self didChangeValueForKey:@"dwellClickCount"];
	[self willChangeValueForKey:@"manualClickCount"];
	manualClickCount=0;
	[self didChangeValueForKey:@"manualClickCount"];
	[self saveClickCounts];
	ignoreCount=YES;
}

// click counter update delay
#define DC_CLICK_COUNTER_DELAY 0.1

- (void)incrementDwellClickCount
{
    NMRunAsyncOnMainThreadWithDelay(DC_CLICK_COUNTER_DELAY, ^{
        if(!ignoreCount&&[[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsClickCountOn])
        {
            [self willChangeValueForKey:@"dwellClickCount"];
            dwellClickCount+=1;
            [self didChangeValueForKey:@"dwellClickCount"];	
        }
        ignoreCount=NO;
    });
}

- (void)userPerformedManualClick
{
	NMRunAsyncOnMainThreadWithDelay(DC_CLICK_COUNTER_DELAY, ^{
		if(!ignoreCount&&[[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsClickCountOn])
		{
			[self willChangeValueForKey:@"manualClickCount"];
			manualClickCount++;
			[self didChangeValueForKey:@"manualClickCount"];		
		}
		ignoreCount=NO;
	});
}


#pragma mark AAccessors

- (void)setDwellClickOn:(BOOL)state
{
	if (state==YES && !self.dwellClickOn) {
		if ([NMUniversalAccessHelper sharedInstance].axEnabled) {
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:DCPrefsAutoClickOn];	
			if (![[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsHasRunTutorial]) {
				NMRunAsyncOnMainThread(^{
					[(DCAppDelegate *)delegate needsTutorial];
				});
			}
		}
		else {
			NMRunAsyncOnMainThread(^{
				[(DCAppDelegate *)delegate needsAX];	
			});
		}
	}
	else if (state==NO && self.dwellClickOn) {
        if (clickMachine.dragging) {
            [self draggingOtherButtonDown];
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DCPrefsAutoClickOn];
	}
}

- (BOOL)dwellClickOn
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsAutoClickOn];
}

- (void)setAutoClickOn:(BOOL)state
{
	[[NSUserDefaults standardUserDefaults] setBool:!state forKey:DCPrefsDefaultClick];
}

- (BOOL)autoClickOn
{
	return ![[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsDefaultClick];
}


@end
