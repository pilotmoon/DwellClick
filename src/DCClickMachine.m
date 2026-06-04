// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCClickMachine.h"
#import "DCEngine+Gubbins.h"
#import "DCClickEvent.h"
#import "DCConstants.h"
#import "NMKit/NMMouseUtils.h"
#import "NMKit/NMUniversalAccessHelper.h"
#import "NMKit/NMPoint.h"

@implementation DCClickMachine
@synthesize nextDrop;

- (DCUniqueSelection *)noSelectionObject
{
	static DCClick *noClickInstance = nil;
	if(!noClickInstance) {
		noClickInstance = [[DCClick alloc] initWithTarget:nil
												 selector:nil
													group:self
													 name:@"No-Click"
													 type:DCClickTypeNone
													 drop:nil];
	}
	return noClickInstance;
}

// Override to save previous value
- (void)setSelectedItem:(DCUniqueSelection *)item
{
	NMLogInfo(@"[Click Machine] Selection is now %@", [item name]);
	[super setSelectedItem:item];
}

// Determine value for the dragging property.
- (BOOL)isDragging
{
	return nextDrop != nil;
}

#pragma mark Next action


- (void)performNextAction // should be invoked from dwell only
{
	// The click event
	DCClickEvent *event=[[DCClickEvent alloc] initWithSelectedClick:(DCClick *)self.selectedItem
															 source:DCEventSourceDwell];	
	[self performEvent:event];
}

- (void)reallyPerformNextAction
{
	DCClickEvent *event=[[DCClickEvent alloc] initWithSelectedClick:(DCClick *)self.selectedItem
															 source:DCEventSourceCommand];	
	[self performEvent:event];
}	

- (void)performEvent:(DCClickEvent *)event
{			
	DCEngine *engine=[DCEngine sharedInstance];
	if (![NMUniversalAccessHelper sharedInstance].axEnabled) {
		engine.dwellClickOn=NO;
	}
	if (!engine.dwellClickOn) {
		return;
	}
	if (engine.override) {
		return;
	}	
	if (event.actualClick==DCClickMouseUp||!engine.holdDrag) {
		if (self.dragging) {
			event.actualClick=nextDrop;
            engine.holdDrag=NO;
		}		
	}

    if (engine.mouseInPanel && event.actualClick!=DCClickDenied) {
        event.actualClick=DCClickPanelButtonClick;
    }
	else if (event.source==DCEventSourceDwell)
	{
        DCClickIntelligence *intel=engine.intel;		
        
        // apply special click if not already dragging
        if (!self.dragging)
        {	
            if ([engine consumePendingFnPopup])
            {
                event.actualClick=DCClickPopup;
            }
            else if(engine.popupsController.mouseActiveInPopup)
            {
                event.actualClick=DCClickPopupButtonClick;
            }
            else
            {
                DCClick *special=[intel specialClickWithEvent:event];
                if (special)
                {
                    NMLogInfo(@"[Intelligence] Changing to special click: %@", [special name]);
                    event.actualClick=special;
                }
            }
        }

        // see if action is allowed here
        if (![intel canClickWithEvent:event]) {
            [event markAsCancelled:intel.lastBlockReason];
            return;
        }

        // one finger blocking
        BOOL allowOneFingerBlock=YES;
        if (event.actualClick.type==DCClickTypePopupButton) {
            allowOneFingerBlock=NO;
        }

        if (allowOneFingerBlock&&[intel wouldOneFingerBlock:self.dragging]) {
            if ([[NSUserDefaults standardUserDefaults] integerForKey:DCPrefsPreventClickWhenOneFingerOnPad]==2) {
                event.actualClick=DCClickPopup;
            }	
            else {
                [event markAsCancelled:intel.lastBlockReason];  //why not?
                return;
            }
        }
	}
	
	/* Mouse Up is a special click, it is never invoked; rather it does the following: */
	if (event.selectedClick.type==DCClickTypeMouseUp)
	{
		if (!self.dragging)
		{
			[event markAsCancelled:@"Can't mouse up when mouse is already up!"];
			return;
		}
	}
	
	// Do the next action
	[self willChangeValueForKey:@"dragging"];
	if (self.dragging)
	{
		if (!engine.holdDrag)
		{
			[event.actualClick performWithObject:event];
			nextDrop = nil;
		}
	}
    else
    {
		// post mouse move first (fixes spotify problem with popups)
		if (![[NMPoint currentFlippedMouseLocation] isEqual:event.uiState.mouseFlippedLocation]) {
			NMPostMouseEvent(kCGEventMouseMoved, [event.uiState.mouseFlippedLocation cgPoint], 0);
		}
		
		// Do the click!
		[event.actualClick performWithObject:event];
		
		// Set up for the drop if necessary
		if([event.actualClick type]==DCClickTypeDragBegin)
		{
			nextDrop = event.actualClick.drop;
			if (event.actualClick.options&SELECTION_OPTION_DEFER_DROP) {
                engine.holdDrag=YES;
			}
		}
	}
	[self didChangeValueForKey:@"dragging"];

}

@end
