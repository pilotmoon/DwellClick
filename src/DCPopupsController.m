// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCPopupsController.h"
#import "NMKit/NMPopupWindow.h"
#import "NMKit/NMPopupWindowButton.h"

#import "NMKit/NMPoint.h"
#import "DCCommon.h"
#import "DCConstants.h"
#import "DCTriggerable.h"
#import "DCClickEvent.h"
#import "DCUtils.h"
#import "NMKit/NMMouseUtils.h"
#import "NMKit/NMGeometryUtils.h"
#import "NMKit/NMConfigUtils.h"
#import "DCEngine.h"
#import "DCClickEvent.h"

@implementation DCPopupsController
@synthesize buttonSet;

static NSDictionary *_buttonSetNames;

#pragma mark Private Methods

+ (DCPopupButtonSetIdentifier)buttonSetForFlags:(CGEventFlags)flags
{
    if (flags&kCGEventFlagMaskControl) {
        return DCPopupButtonSetControl;
    }
    if (flags&kCGEventFlagMaskAlternate) {
        return DCPopupButtonSetOption;
    }
    if (flags&kCGEventFlagMaskShift) {
        return DCPopupButtonSetShift;
    }
    if (flags&kCGEventFlagMaskCommand) {
        return DCPopupButtonSetCommand;
    }
    return DCPopupButtonSetNone;
}


- (NSArray *)buttonsForIdentifier:(DCPopupButtonSetIdentifier)identifier
{
	NSMutableArray *result=[NSMutableArray array];
	NSArray *names;
    switch (identifier) {
		case DCPopupButtonSetStandard:
			names=clickButtons;
			break;
		case DCPopupButtonSetStandardWithLock:
			names=alternativeClickButtons;
			break;
		case DCPopupButtonSetShift:
			names=clickButtonsShift;
			break;
		case DCPopupButtonSetControl:
			names=clickButtonsControl;
			break;
		case DCPopupButtonSetOption:
			names=clickButtonsOption;
			break;
		case DCPopupButtonSetCommand:
			names=clickButtonsCommand;
			break;
        default:
            names=nil;
			break;
	}
    if (names) {
		for (NSString *name in names) {
            NSButton *b=availableButtons[name];
            if (b) {
                [result addObject:b];
            }
		}		
	}
	return result;
}

- (void)doPopupForEvent:(DCClickEvent *)event
{	
	if (self.cancelled) {
		return;
	}
    if (event.actualClick!=DCClickPopup) {
        return;
    }
    
    // get buttons
    DCPopupButtonSetIdentifier set=[DCPopupsController buttonSetForFlags:event.uiState.modifiersDown];
    if ((![DCEngine sharedInstance].lockModifier)&&set==DCPopupButtonSetNone) {
        set=[DCPopupsController buttonSetForFlags:[DCEngine sharedInstance].modifierController.flags];
    }
    if (set!=DCPopupButtonSetNone) {
        self.buttonSet=set;
    }
    	
	// get the buttons
    NSArray *theButtons=[self buttonsForIdentifier:buttonSet];
    if (!theButtons || [theButtons count]==0) {
        return;
    }
    
    [[DCEngine sharedInstance] popupWillAppear];
    
    [self doPopupWithButtons:theButtons location:[[event.uiState.mouseFlippedLocation flip] nsPoint]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object==self && [keyPath isEqualToString:@"buttonSet"]) {
		if (self.alive) {
            NMLogInfo(@"change button set");
			[self.popupWindow changeButtons:[self buttonsForIdentifier:buttonSet] nubLocation:self.currentLocation];
		}
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Public methods

- (id)initWithClictionary:(NSDictionary *)clictionary
{
	self=[super init];
	if (!self) return nil;
		
	[self addObserver:self forKeyPath:@"buttonSet" options:0 context:0];
	
	// set up buttons
	NSDictionary *displayNames=[NSDictionary dictionaryWithConfigName:@"DisplayNames"];
	availableButtons=[NSMutableDictionary dictionary];
	
	// for each button in config
	for (NSString *name in [NSSet setWithArray:[NSArray arrayWithConfigName:@"AvailablePopupsClicks"]])
	{
		// create the button with its routine routine
		NSObject<DCTriggerable> *triggerable=(DCSelection *)clictionary[name];
		((NSMutableDictionary *)availableButtons)[name] = [self newButtonWithTitle:displayNames[name]
                                                                              image:[NSImage symbolForName:name]
                                                                        targetBlock:^{
                                                                            [triggerable performTriggeredActionFromPopupWithLocation:[[NMPoint pointWithNSPoint:self.currentLocation] flip]];
                                                                        }];
    }
	NMLogInfo(@"Buttons: %@", availableButtons);	
	
	clickButtons=[NSArray arrayWithConfigName:@"DefaultPopupsClicks"];
	alternativeClickButtons=[NSArray arrayWithConfigName:@"AlternativePopupsClicks"];
	clickButtonsShift=[NSArray arrayWithConfigName:@"ShiftPopupsClicks"];
    clickButtonsControl=[NSArray arrayWithConfigName:@"ControlPopupsClicks"];
    clickButtonsOption=[NSArray arrayWithConfigName:@"OptionPopupsClicks"];
    clickButtonsCommand=[NSArray arrayWithConfigName:@"CommandPopupsClicks"];
	
	return self;
}

- (void)cancelPopup:(BOOL)quick
{
    [super cancelPopup:quick];
    self.buttonSet=DCPopupButtonSetStandard;
}


- (BOOL)mouseEventDuringOverride:(CGEventRef)event type:(CGEventType)type location:(CGPoint)location
{
	BOOL suppress=YES;
	//send it to popupsController
	CGPoint unflippedPoint=CGPointMake(location.x, NMFlipY(location.y));
	NMSetOverridePoint(location, unflippedPoint);
	
	// check if in window
	NSRect windowFrame=[self.popupWindow frame];
	BOOL inWindow=NSPointInRect(NSPointFromCGPoint(unflippedPoint), windowFrame);
	if(inWindow!=self.popupWindow.mouseInWindow) {
		self.popupWindow.mouseInWindow=inWindow;
	}
	
	NSButton *buttonUnderMouse=nil;
	
	// check if in button
	NSArray *buttons=self.popupWindow.currentButtons;
	if(buttons) {
		for(NMPopupWindowButton *button in buttons) {
			BOOL inButton=[button pointInSelf:NSPointFromCGPoint(unflippedPoint)];
			if (inButton) {
				buttonUnderMouse=button;
                [button mouseMoved:[NSApp currentEvent]];
			}
            else if (button.mouseInsideButton) {
                [button mouseExited:[NSApp currentEvent]];
            }
		}		
	}
	
	if ((1<<type)&DOWN_MASK) {
		if (!buttonUnderMouse) {
			suppress=NO;
		}
	}
	else if ((1<<type)&UP_MASK) {
		if (buttonUnderMouse) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[[buttonUnderMouse target] performSelector:[buttonUnderMouse action] withObject:self];
#pragma clang diagnostic pop
		}
	}
	
    // big move detection
    [self checkBoxWithPoint:NSPointFromCGPoint(unflippedPoint)];
    
	return suppress;
}

- (void)engineWillClickWithEvent:(DCClickEvent *)event
{
	if (event.actualClick.type!=DCClickTypePopupButton&&!self.mouseActiveInPopup)
	{
		[self prepareNew];
	}
}

- (void)engineDidClickWithEvent:(DCClickEvent *)event
{
	if (event.actualClick.type==DCClickTypeNone&&!self.mouseActiveInPopup)
	{
		[self doPopupForEvent:event];
	}
}

- (void)clickCompletedWithEvent:(DCClickEvent *)event
{
	if (event.actualClick.type!=DCClickTypePopupButton)
	{
		[self doPopupForEvent:event];
	}	
}

- (void)startBoxDetect
{
    NMSetOverride(YES);
    [super startBoxDetect];
}

- (void)stopBoxDetect
{
    [super stopBoxDetect];
    NMSetOverride(NO);
}


@end
