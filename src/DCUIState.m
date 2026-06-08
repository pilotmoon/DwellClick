// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCUIState.h"
#import "DCUtils.h"
#import "NMKit/NMEventUtils.h"
#import "DCTouchMonitor.h"
#import "DCEngine.h"
#import "NMKit/NMUniversalAccessHelper.h"
#import "NMKit/NMAppUtils.h"
#import "NMKit/NMPoint.h"
#import "DCCursorInfo.h"

static NSSlider *_dcOwnSliderAtFlippedPoint(NMPoint *point, NSWindow **hitWindow)
{
	NSPoint screenPoint=[[point flip] nsPoint];
	for (NSWindow *window in [NSApp windows]) {
		if (![window isVisible] || !NSPointInRect(screenPoint, [window frame])) {
			continue;
		}
		if (hitWindow) {
			*hitWindow=window;
		}
		NSPoint windowPoint=[window convertPointFromScreen:screenPoint];
		NSPoint contentPoint=[window.contentView convertPoint:windowPoint fromView:nil];
		NSView *view=[window.contentView hitTest:contentPoint];
		while (view) {
			if ([view isKindOfClass:[NSSlider class]]) {
				return (NSSlider *)view;
			}
			view=view.superview;
		}
		return nil;
	}
	return nil;
}

@implementation DCUIState
@synthesize mouseFlippedLocation, mouseElement, mouseAppIsBusy, mouseWindow, mouseWindowIsMain, mouseAppId, mousePid, focusedPid, activePid, activeAppId, fingers;
@synthesize tabletProximity, axEnabled, mouseElementRole, mouseWindowTitle, mouseElementParents, mouseElementMenuBar, mouseElementApp, cursorInfo, cursorType, eventFlags;
@synthesize modifiersDown, mouseElementIsOwnSliderFallback;

- (id)initWithFlippedLocation:(NMPoint *)point
{
	mouseFlippedLocation=point;
	
	// get focused pid
	focusedPid=NMFocusedApplicationPID();
	
	// get active pid
	activePid=NMActiveApplicationPID();
    activeAppId=NMBundleIdForPID(activePid);
    
	// event flags
	eventFlags=NMGetCurrentEventFlags();
	
	// get fingers
	fingers=DCTouchMonitorFingers;
	
	// table proximity
	tabletProximity=DCTapData->tabletProximity;

	// as api enabled
	axEnabled=[NMUniversalAccessHelper sharedInstance].axEnabled;
	
	cursorInfo=[DCCursorInfo currentCursorInfo];
	cursorType=cursorInfo.classification;
    
	// get element
	mouseElement=[NMUIElement elementAtLocation:mouseFlippedLocation timeout:0.1];
	if (!mouseElement) {
		NSWindow *ownSliderWindow=nil;
		NSSlider *ownSlider=_dcOwnSliderAtFlippedPoint(mouseFlippedLocation, &ownSliderWindow);
		if (ownSlider) {
			mouseElementIsOwnSliderFallback=YES;
			mouseElementRole=@"AXSlider";
			mouseElementParents=[NSSet setWithObject:@"AXSlider"];
			mousePid=[[NSProcessInfo processInfo] processIdentifier];
			mouseAppId=DCProductID();
			mouseWindowTitle=ownSliderWindow.title;
			mouseWindowIsMain=ownSliderWindow.isMainWindow;
		}
	}
	
	modifiersDown=[DCEngine sharedInstance].modifiersDown;
		
	// see if the app was busy
	if (!mouseElement) {
		if (!mouseElementIsOwnSliderFallback) {
			if ([NMUIElement lastError]!=kAXErrorSuccess) {
				NMLogInfo(@"[UISnapshot] Could not get UI element; error was %d", (int)[NMUIElement lastError]);
			}
			else {
				NMLogInfo(@"[UISnapshot] App is busy.");
				mouseAppIsBusy=YES;
			}
		}
	}
	else {
		mouseElementRole=mouseElement.role;
		mouseElementApp=mouseElement.appElement;
		mouseElementMenuBar=mouseElementApp.menuBarDirect;
		mouseWindow=mouseElement.windowElement;
		mouseWindowTitle=mouseWindow.title;
		mouseWindowIsMain=mouseWindow.main;
		mousePid=mouseElement.pid;
		mouseElementParents=[NSSet setWithArray:mouseElement.ownAndParentRoles];
		mouseAppId=NMBundleIdForPID(mousePid);
	}

	[cursorInfo logCursorWithContext:@"ui-state"
							   appId:mouseAppId ?: activeAppId
								role:mouseElementRole
							   point:[[mouseFlippedLocation flip] nsPoint]];
	
	return self;
}

+ (DCUIState *)currentState
{
	return [[DCUIState alloc] initWithFlippedLocation:[NMPoint currentFlippedMouseLocation]];
}

@end
