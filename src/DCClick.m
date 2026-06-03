// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCClick.h"
#import "DCClickMachine.h"
#import "DCEngine.h"
#import "DCUtils.h"
#import "DCConstants.h"

@implementation DCClick
@synthesize icon, drop, type;

// Designated initialiser.
- (id)initWithTarget:(id)aTarget
			selector:(SEL)aSelector
	  group:(DCSelectionGroup *)aGroup
				name:(NSString *)aName
				type:(DCClickType)aType
				drop:(DCClick *)aDrop
{
	self = [super initWithName:aName
						 group:aGroup
						target:aTarget
					  selector:aSelector];
	
	type = aType;
	drop = aDrop;
	return self;
}

// applescript specifier says this object lives in the application
- (NSScriptObjectSpecifier *)objectSpecifier{
	NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];
	return [[NSNameSpecifier alloc] initWithContainerClassDescription:containerClassDesc
													containerSpecifier:nil
																   key:@"actions"
																  name:[self name]];
}

- (void)selectSelfOrSurrogate
{
    if (self.options&ALL_MODIFIER_OPTIONS) {
        if (self.type==DCClickTypeSingle) {
            DCClickSingleClick.selected=YES;
        }
        else if (self.type==DCClickTypeDragBegin) {
            DCClickDrag.selected=YES;
        }
    }
    else {
        self.selected=YES;
    }
}

// immediate perform click (from script or otherwise)
- (void)perform:(NSScriptCommand*)command
{
	NSTimeInterval dwelledFor=[[[DCEngine sharedInstance] tap] dwelledTime]; 
	NMLogInfo(@"dwelled for %f", dwelledFor);
    [self selectSelfOrSurrogate];
    [self setModifierForThisClick];    
	if (dwelledFor>=0.06) {
		[[[DCEngine sharedInstance] dwellMachine] performInstant];
	}
	else {
		[[[DCEngine sharedInstance] dwellMachine] performNow];		
	}
}

// perform from popup
- (void)performTriggeredActionFromPopupWithLocation:(NMPoint *)location
{
	NMLogInfo(@"popup location %@", location);
    [self selectSelfOrSurrogate];    
    [self setModifierForThisClick];
	DCClickEvent *event=[[DCClickEvent alloc] initWithSelectedClick:self
															 source:DCEventSourcePopup
													flippedLocation:location];
	[[[DCEngine sharedInstance] clickMachine] performEvent:event];
	[[[DCEngine sharedInstance] dwellMachine] performSilent];	
}

// if perform from keyboard then we might want to do it now
- (void)performTriggeredActionFromKeyboard
{
	DCEngine *engine=[DCEngine sharedInstance];
	if (engine.clickMachine.dragging) {
		return;
	}
    [self perform:nil];
}

- (void)setModifierForThisClick
{
    DCEngine *engine=[DCEngine sharedInstance];
    if (self.options&SELECTION_OPTION_MODIFIED_COMMAND) {
        if (!(engine.modifierController.flags&kCGEventFlagMaskCommand)) {
            [engine.modifierController setFlags:kCGEventFlagMaskCommand];                    
        }
    }
    else if (self.options&SELECTION_OPTION_MODIFIED_CONTROL) {
        if (!(engine.modifierController.flags&kCGEventFlagMaskControl)) {
            [engine.modifierController setFlags:kCGEventFlagMaskControl];                    
        }
    }
    else if (self.options&SELECTION_OPTION_MODIFIED_OPTION) {
        if (!(engine.modifierController.flags&kCGEventFlagMaskAlternate)) {
            [engine.modifierController setFlags:kCGEventFlagMaskAlternate];                    
        }
    }
    else if (self.options&SELECTION_OPTION_MODIFIED_SHIFT) {
        if (!(engine.modifierController.flags&kCGEventFlagMaskShift)) {
            [engine.modifierController setFlags:kCGEventFlagMaskShift];                    
        }
    }
}

- (BOOL)isComplete
{
	return (1<<type)&(1<<DCClickTypeNone|1<<DCClickTypeSingle|1<<DCClickTypeDragEnd|1<<DCClickTypeDouble|1<<DCClickTypeTriple);
}

- (BOOL)isBeginning
{
	return (1<<type)&(1<<DCClickTypeNone|1<<DCClickTypeSingle|1<<DCClickTypeDragBegin|1<<DCClickTypeDouble|1<<DCClickTypeTriple);
}

@end
