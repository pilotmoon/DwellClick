// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCClickIntelligence.h"
#import "DCClickEvent.h"
#import	"NMKit/NMUniversalAccessHelper.h"
#import "DCScrollDetector.h"
#import "DCEngine.h"
#import "DCConstants.h"
#import "DCUtils.h"
#import "DCTouchMonitor.h"
#import "DCCommon.h"
#import "NMKit/NMPoint.h"
#import "NMKit/NMCursorUtils.h"
#import "NMKit/NMConfigUtils.h"

static NSRect _topRect(NSPoint origin, NSSize size, CGFloat d)
{
	NSRect r=NSMakeRect(origin.x, origin.y, size.width, d);
	return r;
}

static BOOL _elementAppIsFocused(DCUIState *uiState)
{
	//NMLogInfo(@"focused %d mouse %d", uiState.focusedPid, uiState.mousePid);
	return uiState.focusedPid==uiState.mousePid;
}

static BOOL _elementAppIsCurrentProcess(DCUIState *uiState)									
{
	return [[NSProcessInfo processInfo] processIdentifier]==uiState.mousePid;
}

// is element a direct child of the menu bar
static BOOL _elementIsInMenuBar(NMUIElement *element)
{
    return [element.parentElement.role isEqualToString:(NSString *)kAXMenuBarRole];
}

// is element any kind of menu item
static BOOL _elementIsMenuItem(NMUIElement *element)
{
    return [element.role isEqualToString:(NSString *)kAXMenuItemRole] || [element.role isEqualToString:(NSString *)kAXMenuBarItemRole];
}

static BOOL _eventLooksSliderLike(DCClickEvent *event)
{
    DCUIState *uiState=event.uiState;
    if (uiState.mouseElementIsOwnSliderFallback) {
        return YES;
    }
    if ([uiState.mouseElementRole isEqualToString:@"AXSlider"] ||
        [uiState.mouseElementRole isEqualToString:(NSString *)kAXValueIndicatorRole]) {
        return YES;
    }
    return [uiState.mouseElementParents containsObject:@"AXSlider"] || [uiState.mouseElementParents containsObject:(NSString *)kAXValueIndicatorRole];
}

// is this a menu item we should not click on
static BOOL _isProtectedMenuItem(NMUIElement *element)
{
    // is a disabled menu item within a menu
    if (_elementIsMenuItem(element) && !element.enabled && !_elementIsInMenuBar(element)) {
        return YES;
    }
    
    // it is a selected element with children
    if  (element.selected && element.hasChildren) {
        return YES;
    }
    
    return NO;
}

static BOOL _isYosemiteSafariBar(DCUIState *state)
{
    const NSString *safariId=@"com.apple.Safari";
    BOOL result=NO;
    
    // yosemite safari
    if ([state.mouseAppId isEqualToString:NMBrowserHelperIdentifierSafari]&&
        [state.activeAppId isEqualToString:NMBrowserHelperIdentifierSafari]&&
        !NMOSVersionCheckMavericksOrBelow())
    {
        NMUIElement *textElement=nil;
        if ([state.mouseElementParents containsObject:NSAccessibilityToolbarRole]&&![state.mouseElementParents containsObject:NSAccessibilityScrollAreaRole]) {
            if ([state.mouseElementRole isEqualToString:NSAccessibilityTextFieldRole]||
                [state.mouseElementRole isEqualToString:NSAccessibilityStaticTextRole]) {
                textElement=state.mouseElement;
            }
            else if ([state.mouseElementRole isEqualToString:NSAccessibilityGroupRole]) {
                NSArray *children=[state.mouseElement children];
                for (id child in children) {
                    NMUIElement *e=[[NMUIElement alloc] initWithElement:(AXUIElementRef)child];
                    if ([[e role] isEqualToString:NSAccessibilityTextFieldRole]) {
                        textElement=e;
                        break;
                    }
                }
            }
            if (textElement) {
                id axValue=[textElement genericAttributeWithName:kAXValueAttribute];
                if ([axValue isKindOfClass:[NSString class]]) {
                    result=YES;
                }
            }
        }
    }
    
    return result;
}

static inline BOOL _isAtEdgeOfRect(NSPoint point, NSRect frame)
{
    // 0,0 is bottom left.
	// tolerance: left & right: 1, top: 4, bottom: 2.
	NSRect innerFrame=frame;
	innerFrame.origin.x+=1;
	innerFrame.size.width-=2;
	innerFrame.origin.y+=2;
	innerFrame.size.height-=6;

    // adjust as being ON the edge doesn't count
    NSRect outerFrame=frame;
    outerFrame.size.height+=0.1;
    outerFrame.size.width+=0.1;    
    
    const BOOL inOuterFrame=NSPointInRect(point, outerFrame);
    const BOOL inInnerFrame=NSPointInRect(point, innerFrame);
    
	return (inOuterFrame && !inInnerFrame);
}

#define CHROME_BAR_HEIGHT 36
#define DRAG_BAR_HEIGHT 21
#define SMALL_DRAG_BAR_HEIGHT 15
static BOOL _isWindowDragBar(DCUIState *uiState)
{
	// special for google chrome bar
	BOOL isChromeBar=NO;
	BOOL isToolBar=NO;
	NMUIElement *element=uiState.mouseElement;

	// find top level window
	NMUIElement *window=nil;
	NSString *role=[element role];

    NMLogFine(@"(dragbar) ROLE %@", role);
	
	if ([role isEqualToString:(NSString *)kAXWindowRole])
	{
		// it is the window
		window=element;
	}
	else
	{
		// special test
		BOOL isChrome=[uiState.mouseAppId isEqualToString:@"com.google.Chrome"];
		isChromeBar=(isChrome && [role isEqualToString:(NSString *)kAXTabGroupRole]);
        
		// is it draggable area in tool bar
		NMUIElement *parent=[element parentElement];
		isToolBar=[role isEqualToString:(NSString *)kAXToolbarRole] || ([role isEqualToString:(NSString *)kAXGroupRole] && [[parent role] isEqualToString:(NSString *)kAXToolbarRole]);
		
		// only search parents of text or images (not buttons or other controls)
		if ([role isEqualToString:(NSString *)kAXStaticTextRole] || [role isEqualToString:(NSString *)kAXImageRole]
			|| (isToolBar&&(!isChrome)) || isChromeBar)		
		{
			window=[element windowElement];
		}
	}	
	
	if (window)
	{
		if (_elementAppIsCurrentProcess(uiState) &&
            ([[window subRole] isEqualToString:(NSString *)kAXSystemFloatingWindowSubrole]||[[window subRole] isEqualToString:(NSString *)kAXSystemDialogSubrole]))
		{
			return YES;
		}
		
		if (_elementAppIsFocused(uiState)||[[NSUserDefaults standardUserDefaults] boolForKey:@"DragInactiveWindows"])
		{			
			// only click on bars with a close button
			NMUIElement *closeButton=[window closeButtonElement];
			NSRect cbrect=NSZeroRect;
			if (closeButton) {
				cbrect.origin=[closeButton origin];
				cbrect.size=[closeButton size];
			}
			
			NMUIElement *minButton=[window minimizeButtonElement];
			NSRect minbrect=NSZeroRect;
			if (minButton) {
				minbrect.origin=[minButton origin];
				minbrect.size=[minButton size];
			}
			
			NMUIElement *maxButton=[window zoomButtonElement];
			NSRect maxbrect=NSZeroRect;
			if (maxButton) {
				maxbrect.origin=[maxButton origin];
				maxbrect.size=[maxButton size];
			}
			
			NMUIElement *toolButton=[window toolbarButtonElement];
			NSRect toolbrect=NSZeroRect;
			if (toolButton) {
				toolbrect.origin=[toolButton origin];
				toolbrect.size=[toolButton size];
			}
			
			// mouse point
			NSPoint absMouse=[[uiState mouseFlippedLocation] nsPoint];
			if (NSPointInRect(absMouse, cbrect) || NSPointInRect(absMouse, minbrect) ||
				NSPointInRect(absMouse, toolbrect) || NSPointInRect(absMouse, maxbrect)) {
				return NO;
			}

            /* Special case for tweetbot: auto drag in top 52 pixels if subrols is AXUnknown */
            CGFloat specialBarHeight=0;
            if ([uiState.mouseAppId isEqualToString:@"com.tapbots.TweetbotMac"]&&[[window subRole] isEqualToString:(NSString *)kAXUnknownRole]) {
                specialBarHeight=52;
            }
            
			if (specialBarHeight>0 || (closeButton && (cbrect.origin.y-window.origin.y<50) /* hack for fullscreen detection*/) )
			{
				// calculate bar height based on close button height
				CGFloat barHeight=(cbrect.origin.y-window.origin.y)*2+cbrect.size.height;
                if (specialBarHeight>0) {
                    barHeight=specialBarHeight;
                }
                else if (isChromeBar) {
                    barHeight=CHROME_BAR_HEIGHT;
                }

				if ([window main] ||
					[[window subRole] isEqualToString:(NSString *)kAXFloatingWindowSubrole] ||
					[[window subRole] isEqualToString:(NSString *)kAXSystemFloatingWindowSubrole] ||
					[[window subRole] isEqualToString:(NSString *)kAXDialogSubrole] ||
                    [[window subRole] isEqualToString:(NSString *)kAXSystemDialogSubrole] ||
                    specialBarHeight>0)
				{
					if (isToolBar) return YES;
					return NSPointInRect(absMouse, _topRect(window.origin, window.size, barHeight));		
				}				
			}
		}
	}
	
	return NO;
}

// is this click a click on the desktop
static BOOL _clickedOnDesktop(DCClickEvent *event)
{
	DCUIState *uiState=event.uiState;
	NMUIElement *element=uiState.mouseElement;
	if ([uiState.mouseAppId isEqualToString:@"com.apple.finder"])
	{
        NSArray *const parents=[element parents];
        const NSInteger lastButOne=[parents count]-2;
        if (lastButOne>=0)
        {
            if ([[parents[lastButOne] role] isEqualToString:(NSString *)kAXScrollAreaRole])
            {
                NMLogFine(@"Clicked on desktop");
                return YES;
            }            
        }
	}
	return NO;
}

// mouse clicked into a new app or app window (not including desktop)
static BOOL _clickedIntoNewFocus(DCClickEvent *event)
{
    static NSSet *roles=nil;
    if (!roles) {
        roles=[NSSet setWithObjects:(id)kAXFloatingWindowSubrole, (id)kAXSystemFloatingWindowSubrole, (id)kAXDialogSubrole, (id)kAXSystemDialogSubrole, @"AXUnknown", nil];
    }
	DCUIState *uiState=event.uiState;
	if (_elementAppIsFocused(uiState))
	{
        if (uiState.mouseWindowIsMain ||
			!uiState.mouseWindow ||
			[roles containsObject:uiState.mouseWindow.subRole])
		{
			return NO;
		}
	}
	return YES;
}

@implementation DCClickIntelligence
@synthesize lastBlockReason;
- (void)updateApps
{
	NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:DCPrefsApplicationList];
	if (array != nil)
	{
		[apps removeAllObjects];
		for(NSDictionary *d in array)
		{
			[apps addObject:d[@"bundleId"]];
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self updateApps];
}

- (id)init
{
	if (!(self=[super init])) return nil;

	// hashes of cursors that shouls cause auto drag
	resizers=[NSMutableSet setWithObjects:
			  @([[NSCursor resizeLeftCursor] superFastHash]),
			  @([[NSCursor resizeRightCursor] superFastHash]),
			  @([[NSCursor resizeLeftRightCursor] superFastHash]),
			  @([[NSCursor resizeUpCursor] superFastHash]),
			  @([[NSCursor resizeDownCursor] superFastHash]),
			  @([[NSCursor resizeUpDownCursor] superFastHash]),
			  nil];
	
	[(NSMutableSet *)resizers addObjectsFromArray:[NSArray arrayWithConfigName:@"ResizeCursorsSFH"]];

	// roles that quick drag can't work on
	quickDragDisallowedRoles=[NSSet setWithObjects:
							/** these should be common with popup roles */
							(NSString *)kAXButtonRole,
							(NSString *)kAXMenuItemRole,
							(NSString *)kAXMenuButtonRole,
							(NSString *)kAXMenuBarItemRole,
							(NSString *)kAXMenuBarRole,
							(NSString *)kAXMenuRole, 
							(NSString *)kAXCheckBoxRole,
							(NSString *)kAXPopUpButtonRole,
							(NSString *)kAXColorWellRole,
							(NSString *)kAXDisclosureTriangleRole,
							(NSString *)kAXRadioButtonRole,
							  
							/** these differ */  
							(NSString *)kAXDockItemRole,
							nil];

	// apps that move the mouse which we should ignore
	mouseMovingApps=[NSSet setWithArray:[NSArray arrayWithConfigName:@"MouseMovingApps"]];
		
	// blocked apps
	apps=[NSMutableSet set];
	[self updateApps];
	[self observePrefsKey:DCPrefsApplicationList];
		
	return self;
}


- (DCClick *)specialClickWithEvent:(DCClickEvent *)event
{	
	DCUIState *uiState=event.uiState;
	NMUIElement *element=uiState.mouseElement;
	
	// Popup
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IgnoreFnKey"]&&uiState.modifiersDown&kCGEventFlagMaskSecondaryFn)
    {
		return DCClickPopup;
	}
	
	// Auto Drag	
	BOOL sliderLike=_eventLooksSliderLike(event);
	if ((element || sliderLike) &&
        [[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsAutoClickOn] &&
        [[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsAutoDragOn] &&
        [DCEngine sharedInstance].defaultClick.selected &&
        ![DCEngine sharedInstance].lockModifier &&
        !_isYosemiteSafariBar(uiState))
    {
        if (sliderLike ||
            [resizers containsObject:uiState.cursorHash] ||
            [element.role isEqualToString:(NSString *)kAXGrowAreaRole] ||
            [element.role isEqualToString:(NSString *)kAXValueIndicatorRole] ||
            [element.role isEqualToString:(NSString *)kAXScrollBarRole] ||
            (NMOSVersionCheckSnowLeopardOrBelow() && [uiState.mouseElementParents containsObject:(NSString *)kAXWindowRole] && DCScrollBarAtPoint([uiState.mouseFlippedLocation nsPoint])) ||
            _isWindowDragBar(uiState))
        {
            return DCClickAutoDragClick;  
        }
    }

	return nil;
}

- (BOOL)activeAppIsBlocked
{
	// are we exclude or including the list
	BOOL exclude=[[NSUserDefaults standardUserDefaults] integerForKey:DCPrefsApplicationFilterType]==0;
	
	// the clicked-on item
	BOOL allow=YES;
	
	// the active item
	if ([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsApplicationFilterBlockAll]) {
		NSString *activeId=[[NSWorkspace sharedWorkspace] activeApplication][@"NSApplicationBundleIdentifier"];
		BOOL inList=[apps containsObject:activeId];
		allow=exclude?!inList:inList;
	}
	
	return !allow;
}

- (BOOL)wouldOneFingerBlock:(BOOL)dragging
{
    if (DCTapData->maxFingers>0) {
        const NSInteger clickMode=[[NSUserDefaults standardUserDefaults] integerForKey:DCPrefsPreventClickWhenOneFingerOnPad];
        const NSInteger dragMode=[[NSUserDefaults standardUserDefaults] integerForKey:DCPrefsPreventDragReleaseWhenOneFingerOnPad];
        
        if (DCTouchMonitorFingers>0) {
            if (dragging) {
                if (dragMode==1){
                    lastBlockReason=@"Finger was not lifted from trackpad";
                    return YES;
                }
            }
            else {
                if (clickMode==1||clickMode==2) {
                    lastBlockReason=@"Finger was not lifted from trackpad";
                    return YES;
                }
            }
        }
        else {
            if (dragging) {
                if (dragMode==2) {
                    lastBlockReason=@"Finger was lifted from the trackpad";
                    return YES;
                }
            }
            else {
                if (clickMode==3) {
                    lastBlockReason=@"Finger was lifted from the trackpad";
                    return YES;
                }
            }
        }
    }
    
	return NO;
}

- (BOOL)canClickWithEvent:(DCClickEvent *)event
{
	lastBlockReason=@"None";
	DCUIState *uiState=event.uiState;
	
    // tablet in use
    const BOOL tabletInUse=[DCEngine sharedInstance].tap->tabletProximity;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsEnableTablet]) {
        if (tabletInUse) {
            lastBlockReason=[NSString stringWithFormat:@"Tablet is in use"];
            return NO;
        }
    }
    
	// banned movement app blocking
	if ([mouseMovingApps containsObject:event.movementCausedByApp]) {
		lastBlockReason=[NSString stringWithFormat:@"Mouse was moved by %@", event.movementCausedByApp];
		return NO;
	}
	
	// scroll wheel condition
	if (event.scrollWheelWasUsed) {
		lastBlockReason=@"The scroll wheel was used or a scroll gesture was performed.";
		return NO;
	}
	// multi touch two finger blocking
	if (event.maxFingers>1)
	{
		lastBlockReason=@"Trackpad gesture.";
		return NO;
	}		
	
	// app switch condition
	//NMLogInfo(@"initial pid %d pid %d", event.initialActivePid, event.uiState.activePid);
	if (event.initialActivePid!=event.uiState.activePid) {
		lastBlockReason=@"The active application changed.";
		return NO;
	}
	
	// Screen Edges and Corners
	if (![DCEngine sharedInstance].clickMachine.dragging ||
		[[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsAvoidEdgesWhenDragging])
	{
		NSPoint p=[[uiState.mouseFlippedLocation flip] nsPoint];
		for (NSScreen *s in [NSScreen screens])
		{
            NSRect r=[s frame];
            NMLogTiny(@"Checking point %@ in screen frame %@", NSStringFromPoint(p), NSStringFromRect(r));

            if ([uiState.mouseFlippedLocation isWithinDistance:5 ofCornerOfRect:r])
            {
                lastBlockReason=@"Pointer is in corner of screen.";
                return NO;	
            }
            if (_isAtEdgeOfRect(p, r)) {
                if (![uiState.mouseElementRole isEqualToString:(NSString *)kAXMenuBarItemRole]) {
                    lastBlockReason=@"Pointer is at edge or side of screen.";
                    return NO;
                }
            }
		}		
	}
	
	// Busy app
	if (uiState.mouseAppIsBusy)
	{
		lastBlockReason=@"The application did not respond in time to determine the UI element.";
		return NO;
	}
	
	// this can be null in which case assume click is OK
	NMUIElement *element=uiState.mouseElement;
	
	// Smart Menu
	if (_isProtectedMenuItem(element))
    {
        lastBlockReason=@"Item under pointer is a menu title or disabled menu item.";
        return NO;
    }
	
	// Application Blocking
	if ([apps count]>0 && ![uiState.mouseAppId isEqualToString:DCProductID()])
	{	
		// are we esclude or including the list
		BOOL exclude=[[NSUserDefaults standardUserDefaults] integerForKey:DCPrefsApplicationFilterType]==0;
		
		// the clicked-on item
		BOOL inList=[apps containsObject:uiState.mouseAppId];
		BOOL allow=exclude?!inList:inList;
		
		// the active item
		if (allow&&[[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsApplicationFilterBlockAll]) {
			NSString *activeId=[[NSWorkspace sharedWorkspace] activeApplication][@"NSApplicationBundleIdentifier"];
			inList=[apps containsObject:activeId];
			allow=exclude?!inList:inList;
		}
		
		if (!allow)
		{
			lastBlockReason=@"Application blocking rules prevented this click.";
			return NO;		
		}
	}
	
	return YES;
}

- (BOOL)canQuickDragWithEvent:(DCClickEvent *)event
{	
    if ([DCEngine sharedInstance].lockModifier) {
        return NO;
    }
    if (event.uiState.mouseElementIsOwnSliderFallback) {
        return NO;
    }
    NMUIElement *window=event.uiState.mouseWindow;
    if (!window && [event.uiState.mouseElementRole isEqualToString:(NSString *)kAXWindowRole]) {
        window=event.uiState.mouseElement;
    }
    NSString *windowSubrole=window.subRole;
    if (_elementAppIsCurrentProcess(event.uiState) &&
        ([windowSubrole isEqualToString:(NSString *)kAXDialogSubrole] ||
         [windowSubrole isEqualToString:(NSString *)kAXSystemDialogSubrole] ||
         [windowSubrole isEqualToString:(NSString *)kAXSystemFloatingWindowSubrole]))
    {
        return NO;
    }
	if ([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsQuickDragOn])
	{
		if (_clickedIntoNewFocus(event))
		{
			if (!_clickedOnDesktop(event))
			{
				return NO;
			}
		}
		return ![quickDragDisallowedRoles containsObject:event.uiState.mouseElementRole];
	}
	return NO;
}

@end
