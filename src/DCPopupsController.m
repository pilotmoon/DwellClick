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

#pragma mark Private Methods

- (void)doPopupForEvent:(DCClickEvent *)event
{	
	if (self.cancelled) {
		return;
	}
    if (event.actualClick!=DCClickPopup) {
        return;
    }
    if ([clickButtons count]==0) {
        return;
    }
    
    [[DCEngine sharedInstance] popupWillAppear];
    
    [self doPopupWithButtons:clickButtons location:[[event.uiState.mouseFlippedLocation flip] nsPoint]];
}

#pragma mark Public methods

- (id)initWithClictionary:(NSDictionary *)clictionary
{
	self=[super init];
	if (!self) return nil;
	
	// set up buttons
	NSDictionary *displayNames=[NSDictionary dictionaryWithConfigName:@"DisplayNames"];
	NSMutableArray *buttons=[NSMutableArray array];
	
	// for each button in config
	for (NSString *name in [NSArray arrayWithConfigName:@"DefaultPopupsClicks"])
	{
		// create the button with its routine routine
		NSObject<DCTriggerable> *triggerable=(DCSelection *)clictionary[name];
		NSButton *button=[self newButtonWithTitle:displayNames[name]
                                            image:[NSImage symbolForName:name]
                                      targetBlock:^{
                                          [triggerable performTriggeredActionFromPopupWithLocation:[[NMPoint pointWithNSPoint:self.currentLocation] flip]];
                                      }];
        if (button) {
            [buttons addObject:button];
        }
	}
	clickButtons=[buttons copy];
	NMLogInfo(@"Buttons: %@", clickButtons);
	
	return self;
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
