// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCEngine.h"
#import "DCEngine+Gubbins.h"

#import "DCConstants.h"
#import "DCPrefsController.h"
#import "DCSoundController.h"
#import "DCAppDelegate.h"
#import "DCSimpleTrigger.h"
#import "DCPopupsController.h"
#import "DCUIState.h"
#import "DCTouchMonitor.h"
#import "DCUtils.h"
#import "NMKit/NMKit.h"


DCClick *DCClickNoClick;
DCClick *DCClickSingleClick;
DCClick *DCClickDrag;
DCClick *DCClickHeldDrag;
DCClick *DCClickPopup;
DCClick *DCClickDenied;
DCClick *DCClickAutoDragClick;
DCClick *DCClickAbandonDrag;
DCClick *DCClickMouseUp;
DCClick *DCClickQuickDrag;
DCClick *DCClickPopupButtonClick;
DCClick *DCClickPanelButtonClick;

DCMouseTap *DCTapData;

NSUInteger *DCAnimationPosition;
NSUInteger *DCAnimationHide;

@interface DCEngine()
- (void)fnKeyAction;
- (void)selectDefaultClick;
- (void)selectedClickChanged;
- (void)setPendingFnPopup:(BOOL)state;
@end

@implementation DCEngine
@synthesize delegate, tap, dwellMachine;
@synthesize clickMachine, clictionary, lockCurrentClick, lockModifier, intel, holdDrag;
@synthesize dwellClickCount, manualClickCount, popupsController;
@synthesize mouseInPanel, mouseInActivationArea, override, modifiersDown, modifierController, lastClickedPid=_lastClickedPid;

+ (DCEngine *)sharedInstance
{
	static DCEngine *sharedInstance=nil;
	if (!sharedInstance) {
		sharedInstance=[[DCEngine alloc] init];
	}
	return sharedInstance;
}

- (void)setParams
{
	[self.tap setMoveRadius:[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsMoveDistancePixels]-1];
	[self.tap setDwellTime:[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsDwellTimeSeconds]];
	[self.tap setDwellRadius:[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsDwellDistancePixels]];
}

- (void)toggleDragWithHold:(BOOL)hold
{
    if (clickMachine.dragging) {
        if (self.holdDrag) {
            [self draggingOtherButtonDown]; // cancel drag
        }
        else {
            [self fnKeyAction];
        }
	}
	else {
		[(hold?DCClickHeldDrag:DCClickDrag) perform:nil];
	}
}

- (void)toggleDrag
{
    [self toggleDragWithHold:NO];
}

- (void)toggleHeldDrag
{
    [self toggleDragWithHold:YES];
}

#pragma maek Buttons Down While Dragging

- (void)draggingOtherButtonDown
{
	[clickMachine performEvent:[[DCClickEvent alloc] initWithSelectedClick:DCClickMouseUp
																	source:DCEventSourceButton]];
}

- (void)draggingSameButtonDown
{
	clickMachine.nextDrop=DCClickAbandonDrag;
	[tap setDragType:0];
	[self draggingOtherButtonDown];
}

#pragma mark Special Keys Pressed

#define DC_FN_POPUP_RECENT_MOUSE_MOVE_INTERVAL 0.25

- (void)setPendingFnPopup:(BOOL)state
{
    if (pendingFnPopup==state) {
        return;
    }
    pendingFnPopup=state;
    if (state) {
        [modifierController setNoSelection];
        [symbolController clearUnderlay];
        [symbolController displaySymbolName:@"Popup" style:DCSymbolStyleEmboss];
    }
    else {
        [self selectedClickChanged];
    }
}

- (BOOL)escKeyPressed
{
	BOOL result=NO;
    
    // reset modifiers if need be
    if (!modifierController.noSelection) {
        [modifierController setNoSelection];
        result=YES;
    }

    if (self.lockCurrentClick) {
        self.lockCurrentClick=NO;
    }
    
	if (clickMachine.dragging) {
		[self draggingOtherButtonDown]; // cancel the drag
	}
	else {
		if ([popupsController isAlive]) {
			[popupsController cancelPopup];
			result=YES;
		}
		if (pendingFnPopup) {
			[self setPendingFnPopup:NO];
			result=YES;
		}
		if ((self.autoClickOn || !self.defaultClick.selected)) {
			if ([self isDwellDetecting]) {
				if (DCClickDenied.selected) {
					// allow esc to pass through
				}
				else {
					DCClickDenied.selected=YES;
					result=YES;
				}
			}
		}
	}
	return result;
}

- (void)fnKeyAction
{
	if (clickMachine.dragging) {
		if (self.holdDrag) { 
			[self draggingOtherButtonDown]; // cancel drag
		}
		else {
			self.holdDrag=YES; // lock drag	
		}
	}
	else if ([popupsController isAlive])
    {
        if ([tap mouseMovedWithinTimeInterval:DC_FN_POPUP_RECENT_MOUSE_MOVE_INTERVAL]) {
            [popupsController cancelPopup:YES];
            [self setPendingFnPopup:YES];
        }
	}
	else if (DCClickPopup.selected)
    {
       // already selected
    }
	else if (pendingFnPopup)
    {
        // already requested
    }
    else
    {
        if (self.lockCurrentClick) {
            self.lockCurrentClick=NO;
        }
        if ([tap mouseMovedWithinTimeInterval:DC_FN_POPUP_RECENT_MOUSE_MOVE_INTERVAL]) {
            [self setPendingFnPopup:YES];
        }
        else {
            [DCClickPopup performTriggeredActionFromKeyboard];
        }
    }			
}

#pragma mark Modifier Key Actions

- (void)dispenseAction:(CGEventFlags) flag
{
    if (flag&kCGEventFlagMaskSecondaryFn)
    {
        if([self fnKeyActionIsAllowed]) 
        {
            [self fnKeyAction];
        }
    }
    else
    {
        if([self modifierKeyActionIsAllowed])
        {
            [self setPendingFnPopup:NO];
            DCClick *click=(DCClick *)([clickMachine.selectedItem isKindOfClass:[DCClick class]]?clickMachine.selectedItem:nil);
            const DCClickType type=click.type;
            if (clickMachine.dragging)
            {
                BOOL state=!!(modifierController.flags&flag);
                if (state) 
                {
                    [modifierController setNoSelection];
                }
                else 
                {
                    modifierController.flags=flag;
                }
            }
            else if (popupsController.alive) 
            {
                // popup button sets are fixed
            }
            else 
            {
                if((modifierController.flags&flag || self.lockCurrentClick) && (click.type==DCClickTypeSingle || self.lockCurrentClick))
                {
                    self.modifierController.flags=flag;
                    self.lockModifier=YES;
                    [symbolController displayUnderlayName:[[modifierController flagNames] anyObject] style:
                     DCSymbolStyleKeyHighlight];
                }
                else
                {
                    modifierController.flags=flag;
                }
            }
        }
    }
}

#pragma mark Modifier button processing

- (BOOL)modifierButtonDown:(CGEventFlags)flag
{
    modifiersDown|=flag;
    if (clickMachine.dragging||
        popupsController.mouseInPopup||
        (popupsController.alive&&![self isDwellDetecting]))
    {
        actedOnModifier|=flag;
        [self dispenseAction:flag];
    }
    return NO;
}

- (BOOL)modifierButtonUp:(CGEventFlags)flag
{ 
    modifiersDown&=~flag;
    actedOnModifier&=~flag;
    return NO;
}

// return YES to suppress the event
- (BOOL)modifierButtonPressed:(CGEventFlags)flag
{
    BOOL result=(!(flag&kCGEventFlagMaskSecondaryFn))&&[[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsModifiersOn];
    modifiersDown&=~flag;
    if (!(actedOnModifier&flag)) {
        NMRunAsyncOnMainThread(^{
            [self dispenseAction:flag];
        });
    }
    actedOnModifier&=~flag;
    return result;
}

- (BOOL)clickIsExpected
{
	DCClick *click=(DCClick *)clickMachine.selectedItem;
	return 	((self.dwellClickOn) &&
			 (click.type!=DCClickTypeNone || click==DCClickPopup) &&
			 ![intel activeAppIsBlocked] &&
			 !override &&
             !self.holdDrag &&
			 [NMUniversalAccessHelper sharedInstance].axEnabled);
}

- (BOOL)isDwellDetecting
{
	return [dwellMachine.stateMachine.currentState.name isEqualToString:@"DwellDetect"];
}

- (void)adjustCountdownAnimation
{	
	if ([self clickIsExpected] && !hasDwelled && hasMovedSinceAction) {
		[animWindowController doCountdownAnimation];	
	}
	else {
		[animWindowController stopCountdownAnimation];
	}
}

- (void)popupWillAppear
{
    pendingFnPopup=NO;
    // reset modifier selection
    NMRunAsyncOnMainThread(^{
        [self.modifierController setNoSelection];
        [symbolController displaySymbolName:nil style:0];
    });
}

- (BOOL)consumePendingFnPopup
{
    BOOL result=pendingFnPopup;
    if (result) {
        pendingFnPopup=NO;
        [symbolController clearSymbol];
    }
    return result;
}

# pragma mark State Machine changes

- (void)moveDetected
{
	hasMovedSinceAction=YES;
	[self adjustCountdownAnimation];
}

- (void)restDetected // this is called when the mouse starts to move following a dwell
{
	hasDwelled=NO;
	[self adjustCountdownAnimation];
}


- (void)dwellDetected
{
	hasDwelled=YES;
	[animWindowController stopCountdownAnimation];
}

#pragma mark Activity detected 

- (void)activityDetectedSinceRest:(DCTapActivity)activity
{
	if (activity!=DCTapActivityKeyboard) {
		[animWindowController hideCountdownAnimation];
	}
}

- (void)dragWasLocked
{
    animWindowController.throb=YES;
    [[DCSoundController sharedInstance] playSoundForClickType:DCClickTypeDragLockSound];
}

- (void)activityDetected:(DCTapActivity)activity
{
    NMBasicBlock b=^{
        if(!gotShortcut) {
            if (activity!=DCTapActivityKeyboard) {
                [self setPendingFnPopup:NO];
            }
            [modifierController setNoSelection];
            if (self.lockCurrentClick) {
                self.lockCurrentClick=NO;
            }
            if (!clickMachine.dragging) {
                [self selectDefaultClick];
            }
        }
    };

    gotShortcut=NO;
    if(activity==DCTapActivityKeyboard) {
        NMRunAsyncOnMainThreadWithDelay(0.1,b);
    }
    else if (activity==DCTapActivityButton&&self.mouseInPanel) {
        NMLogFine(@"Mouse clicked in panel");
    }
    else { 
        b();
    }
}

- (void)currentModifierChanged
{
    NMLogTiny(@"Modifiers changed to %@", [modifierController flagNames]);
    if (!self.lockCurrentClick) {
        self.lockModifier=NO;
    }

    tap.dragFlags=modifierController.flags;
    NMRunAsyncOnMainThread(^{
        [symbolController displayUnderlayName:[[modifierController flagNames] anyObject] style:self.lockModifier?DCSymbolStyleKeyHighlight:0];
    });
}

- (void)selectedClickChanged
{
	DCClick *click=(DCClick *)clickMachine.selectedItem;
    NMLogInfo(@"Selected click changed to: %@", click);

    if (pendingFnPopup) {
        [symbolController displaySymbolName:@"Popup" style:DCSymbolStyleEmboss];
        return;
    }

	if ([click isKindOfClass:[DCClick class]])
    {
        // set symbol to show
        [self adjustCountdownAnimation];
        
        if (click.type!=DCClickTypeSingle && self.lockModifier && !self.lockCurrentClick ) {
            self.lockModifier=NO;
            [symbolController displayUnderlayName:[[modifierController flagNames] anyObject] style:0];
        }
        
        NMRunAsyncOnMainThread(^{
            NSString *name=click.name;
            if ([name isEqualToString:@"No-Click"]&&!self.autoClickOn) {
                name=nil;
            }
            else if ([name isEqualToString:@"Click"]&&self.autoClickOn) {
                name=nil;
            }
            else if (clickMachine.dragging){
                name=nil;
            }
            [symbolController displaySymbolName:name style:DCSymbolStyleEmboss];		            
        });
	}
}

# pragma mark Quick Drag

- (void)didQuickDragWithEvent:(DCClickEvent *)event
{
	if (event.actualClick.type==DCClickTypeSingle)
    {
		DCClick *drop=[event.actualClick drop];
		[DCClickQuickDrag performWithObject:nil];
		[clickMachine setNextDrop:drop];
	}
}

#pragma mark Drfault click management

- (void)selectDefaultClick
{
	if (!self.defaultClick.selected) {
        NMLogInfo(@"Selecting Default Click");
		self.defaultClick.selected=YES;
	}
}

- (DCClick *)defaultClick
{
	return ([[NSUserDefaults standardUserDefaults] integerForKey:DCPrefsDefaultClick]==0)?DCClickSingleClick:DCClickNoClick;
}

- (void)handleMouseInPanel
{
    if (self.mouseInPanel) {
        NMLogFine(@"mouse in panel");
    }
    else {
        NMLogFine(@"mouse out of panel");        
    }
}

- (void)handleMouseInActivationArea
{
    if (self.mouseInActivationArea) {
        NMLogFine(@"ACTIVATION IN!");
        if ([NMStatusItemController sharedInstance].ready && ![NMStatusItemController sharedInstance].override) {
            if (!self.dwellClickOn) {
                [activationTimer invalidate];
                activationTimer=[NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults]floatForKey: DCPrefsActivationInterval]
                                                                  block:^{
                                                                      self.dwellClickOn=YES;
                                                                      [[DCSoundController sharedInstance] playSoundForClickType:DCClickTypeHoverOn];
                                                                  } repeats:NO];
                
            }
        }
        else {
            NMLogFine(@"Status item not avail ready %d override %d", [NMStatusItemController sharedInstance].ready, [NMStatusItemController sharedInstance].override);
        }
    }    
    else {
        NMLogFine(@"ACTIVATION OUT!");        
        [activationTimer invalidate];
        activationTimer=nil;
    }
}

- (void)updateStatusItem
{
    [NMStatusItemController sharedInstance].enabled=[NMUniversalAccessHelper sharedInstance].axEnabled&&[DCEngine sharedInstance].dwellClickOn;
}

- (void)handleEnabledChange
{
    [self updateStatusItem];
	if (self.dwellClickOn) {
		if (self.clickMachine.noSelection) {
			[self selectDefaultClick];
		}
        DCTouchMonitorReset();
		dwellMachine.active=YES;
	}
	else {
		[popupsController cancelPopup];
		tap.dragType=0;
		clickMachine.nextDrop=nil;
        self.lockCurrentClick=NO;
		[animWindowController stopFlashAnimation];
		[animWindowController stopCountdownAnimation];
        [modifierController setNoSelection];
        [self modifierButtonUp:NMAllFourModifierFlags];
		[symbolController clearAll];
        DCTouchMonitorReset();
		dwellMachine.active=NO;
        [DCClickNoClick setSelected:YES];
	}
    [self registerHotKeys];    
}

- (void)start
{
	[self setParams];
	[self handleEnabledChange];
}

#pragma mark Pre-and post click stuff

- (void)selectionGroup:(DCSelectionGroup *)group willUseSelection:(DCUniqueSelection *)selection withObject:(id)obj
{
	DCClickEvent *event=obj;
	NMLogInfo(@"[Engine] Will: %@", [selection name]);
	if ([selection class]==[DCClick class])
	{	
		DCClick *click=(DCClick *)selection;
		DCClickType type=[(DCClick *)selection type];
				
		// don't play effect if abandoning drag from what was actually a click
		if (!(click==DCClickAbandonDrag&&previousClick.type!=DCClickTypeDragBegin&&type!=DCClickTypePopupButton))
		{
			// play the sound
			[[DCSoundController sharedInstance] playSoundForClickType:type];	
			
			// play the animation
            // but suppress if 64x40 and ending a drag, as it indicates a probably screen with command-shift-4
            // and we don't want the animation in the shot
            NSSize cursorSize=[[[NSCursor currentSystemCursor] image] size];
            const BOOL shouldSuppressAnimation=cursorSize.width==64&&cursorSize.height==40&&type==DCClickTypeDragEnd;
            
            if (shouldSuppressAnimation) {
                [animWindowController stopFlashAnimation];
            }
            else {
                [animWindowController doFlashAnimationForClickType:type];				
            }
		}

		if (click.beginning)
		{
			previousClick=click;
		}
		
		[popupsController engineWillClickWithEvent:event];
	}
}

- (void)selectionGroup:(DCSelectionGroup *)group didUseSelection:(DCUniqueSelection *)selection withObject:(id)obj
{
	DCClickEvent *event=obj;
	NMLogInfo(@"[Engine] Did:  %@", [selection name]);
	if ([selection class]==[DCClick class])
	{
        [popupsController engineDidClickWithEvent:event];
        
		DCClick *click=(DCClick *)selection;
		DCClickType type=[click type];
		
		hasMovedSinceAction=NO;
		
		if (click.complete && !(click.options&SELECTION_OPTION_PANEL_CLICK))
		{
            if (self.lockCurrentClick)
            {
                NMRunAsyncOnMainThread(^{
                    clickMachine.selectedItem.selected=YES;
                });
            }		
            else
            {
                [self selectDefaultClick];
            }            
        }
        
        if (self.lockCurrentClick&&click==DCClickPopup) {
            self.lockCurrentClick=NO;
        }
         
		// record "last drag begin" events
		if (type==DCClickTypeDragBegin) {
			lastDragStartEvent=(click==DCClickQuickDrag)?lastSingleClickEvent:event;
            [symbolController clearSymbol];
		}
		else if (type==DCClickTypeSingle) {
			lastSingleClickEvent=event;
		}
	}
}

// not called for drag begin or no-click
- (void)eventIsComplete:(DCClickEvent *)event
{
	// act on flags
	NMLogInfo(@"[Engine] Event complete, actual click: %@", event.actualClick.name);
	switch (event.actualClick.options) {
		case SELECTION_OPTION_CUT_AFTER:
			[NMKeyPresser pressCommandX];
			break;
		case SELECTION_OPTION_COPY_AFTER:
			[NMKeyPresser pressCommandC];
			break;
		case SELECTION_OPTION_PASTE_AFTER:
			[NMKeyPresser pressCommandV];
			break;
		default:
			break;
	}
    
    if (event.actualClick!=DCClickPopupButtonClick && 
        event.actualClick!=DCClickPanelButtonClick &&
        !self.lockModifier &&
        !self.lockCurrentClick) {
        [modifierController setNoSelection];
    }
	[popupsController clickCompletedWithEvent:event];
    
    // If it wasn't a No-Click
    if (event.actualClick.type!=DCClickTypeNone) {
        if (event.uiState.mousePid!=getpid()) {
            self.lastClickedPid=event.uiState.mousePid;
        }
        // Tell app delegate we clicked
        [delegate engineDidClick];
    }
}

#pragma mark Observer Method

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object==[NSUserDefaultsController sharedUserDefaultsController]) {
		if ([keyPath hasSuffix:DCPrefsAutoClickOn]) {
			[self handleEnabledChange];
		}
		else if ([keyPath hasSuffix:DCPrefsDefaultClick]) {
			if([self dwellClickOn])
			{
				if (DCClickSingleClick.selected) {
					DCClickNoClick.selected=YES;
				}
				else if (DCClickNoClick.selected) {
					DCClickSingleClick.selected=YES;
				}				
			}
		}
		else {
			[self setParams];
		}			
	}
    else if (object==modifierController)
    {
        [self currentModifierChanged];
    }
	else if (object==self)
    {
		if ([keyPath isEqualToString:@"lockCurrentClick"]) {
			if (!self.lockCurrentClick) {
                [modifierController setNoSelection];
                [self selectDefaultClick];
			}
            else {
                self.lockModifier=YES;
                [symbolController displayUnderlayName:[[modifierController flagNames] anyObject] style:
                 DCSymbolStyleKeyHighlight];
            }
		}
		else if ([keyPath isEqualToString:@"mouseInPanel"]) {
            [self handleMouseInPanel];
		}
        else if ([keyPath isEqualToString:@"mouseInActivationArea"]) {
            [self handleMouseInActivationArea];
		}
	}
	else if (object==clickMachine)
    {
        if ([keyPath isEqualToString:@"selectedItem"]) {
            [self selectedClickChanged];
        }
	}
	else if (object==[NMUniversalAccessHelper sharedInstance])
    {
        [self updateStatusItem];
        
        // UX changed
		if (![NMUniversalAccessHelper sharedInstance].axEnabled)
        {
			if (self.dwellClickOn)
            {
				NMLogInfo(@"AX IS DISABLED: Turning DwellClick Off");
				[(DCAppDelegate *)[(NSApplication *)NSApp delegate] warnAX];
				self.dwellClickOn=NO;
			}
		}
	}
}

- (BOOL)modifierKeyActionIsAllowed
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsModifiersOn] && !self.override && !DCClickDenied.isSelected;
}

- (BOOL)fnKeyActionIsAllowed
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:@"IgnoreFnKey"];
}

- (void)turnDwellClickOnFromPanel
{
    if (!self.dwellClickOn) {
        self.dwellClickOn=YES;
    }
}
	
@end
