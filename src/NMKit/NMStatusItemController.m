// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMStatusItemController.h"
#import "NMKit.h"

NSString *NMStatusItemClickedNotification=@"NMStatusItemClickedNotification";
NSString *NMStatusItemRightClickedNotification=@"NMStatusItemRightClickedNotification";
NSString *NMStatusItemHideIcon=@"NMStatusItemHideIcon";

@interface NMStatusItemController ()
@property NSStatusItem *statusItem;

// attach either a NSMenu or a NMStatusBubbleWindow
@property NSMenu *statusMenu;
@property NMStatusBubbleWindow *statusWindow;

@property BOOL menuIsOpen;
@property BOOL canOpenMenu;
@end

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_9

@interface NSStatusBarButton : NSButton
@property BOOL appearsDisabled;
@end

@interface NSStatusItem (Fake)
@property NSStatusBarButton *button;
@end

#endif

@implementation NMStatusItemController

#pragma mark Singleton class method

+ (NMStatusItemController *)sharedInstance
{
    static NMStatusItemController *sharedInstance=nil;
    if (!sharedInstance) {
        sharedInstance=[[self alloc] init];
    }
    return sharedInstance;
}

#pragma mark Color definitions

+ (NSColor *)defaultColor
{
    return [NSColor blackColor];
}

+ (NSColor *)highlightColor
{
    return [NSColor whiteColor];
}

+ (NSColor *)disabledColor
{
    return [NSColor grayColor];
}

#pragma mark Init

- (id)init
{
    self = [super init];
    if (self)
    {
        self.delegate=[[NSClassFromString([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NMStatusItemDelegateClass"]) alloc] init];
        NSAssert(self.delegate, @"No NMStatusItemDelegateClass in InfoDictionary", nil);
        
        [self displayStatusIcon];
        
        [self addObserver:self forKeyPath:@"enabled" options:0 context:0];
        [self addObserver:self forKeyPath:@"ready" options:0 context:0];
        [self observePrefsKey:NMStatusItemHideIcon];
        [self addObserver:self forKeyPath:@"temporarilyInMenu" options:0 context:nil];
    }
    return self;
}

#pragma mark Getting the status image

- (NSImage *)statusImageWithColor:(NSColor *)color
{
    // template image and
    NSImage *const template=[self.delegate statusItemImage];
    const NSRect imageRect=NMRectFromSize([self.delegate statusItemImageSize]);
    
    NSImage *const statusImage=[[NSImage alloc] init];
    [statusImage setSize:imageRect.size];
    [statusImage lockFocus];
    
    [template drawInRect:imageRect
                fromRect:NSZeroRect
               operation:NSCompositeSourceOver
                fraction:1.0];
    
    // fill with color
    [color set];
    NSRectFillUsingOperation(imageRect, NSCompositeSourceIn);
    
    // done
    [statusImage unlockFocus];
    return statusImage;
}

- (void)updateImage
{
	if ([NSStatusItem instancesRespondToSelector:@selector(button)]) {
		self.statusItem.button.appearsDisabled=!self.enabled;
	}
	else {
		[[self statusItemView] setNeedsDisplay:YES];
	}
}

#pragma mark Add and remove the icon from the menu bar

- (void)addStatusIcon
{
	if (!self.statusItem) {
		
		// status item dimensions
		const NSRect viewFrame=NSMakeRect(0, 0,
										  [self.delegate respondsToSelector:@selector(statusItemWidth)]?self.delegate.statusItemWidth:self.delegate.statusItemImageSize.width+6,
										  [[NSStatusBar systemStatusBar] thickness]);
		
		
        // create status item
        self.statusItem=[[NSStatusBar systemStatusBar] statusItemWithLength:viewFrame.size.width];
        self.statusItem.image=[self statusImageWithColor:[NMStatusItemController defaultColor]];

		if([self.statusItem respondsToSelector:@selector(button)]) {
			[self.statusItem setHighlightMode:YES];
			[self.statusItem.image setTemplate:YES];
			[self.statusItem.button setTarget:self];
			[self.statusItem.button setAction:@selector(statusButtonClicked:)];
			[self.statusItem.button sendActionOn:NSLeftMouseDownMask|NSRightMouseDownMask];
		}
		else {
			// create view
			[self.statusItem setView:[[NMStatusItemView alloc] initWithFrame:viewFrame controller:self]];
		}
		
		// add the tracking area
		[[self statusItemView] addTrackingArea:[[NSTrackingArea alloc] initWithRect:[[self statusItemView] frame]
																			options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
																			  owner:self
																		   userInfo:nil]];
		
        self.canOpenMenu=YES;
		
		[self updateImage];
        [self.statusWindow reattach];
	}
}

- (void)removeStatusIcon
{
	if (self.statusItem) {
        for (NSTrackingArea *ta in [[self statusItemView] trackingAreas]) {
            [[self statusItemView] removeTrackingArea:ta];
        }
		[[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
		self.statusItem=nil;
        self.canOpenMenu=NO;
	}
}

#pragma mark Show or hide the status icon as appropriate

- (void)displayStatusIcon
{
	if (!self.iconVisible&&!self.temporarilyInMenu) {
        [self removeStatusIcon];
	}
    else {
        [self addStatusIcon];
    }
}

#pragma mark Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self displayStatusIcon];
    
    if ([keyPath hasSuffix:NMStatusItemHideIcon]&&!self.iconVisible) {
        BOOL showMessage=YES;
        if ([self.delegate respondsToSelector:@selector(statusItemSuppressRestoreInstructions)]) {
            showMessage=![self.delegate statusItemSuppressRestoreInstructions];
        }
        if (showMessage) {
            const BOOL restoreWindow=self.statusWindow&&self.menuIsOpen;
            [self closeAttachedWindow];
            
            BOOL showRestore=YES;
            if ([self.delegate respondsToSelector:@selector(statusItemHideRestoreButton)]) {
                showRestore=![self.delegate statusItemHideRestoreButton];
            }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-security"
            NSAlert *alert=[NSAlert alertWithMessageText:NMLocalS(@"Icon Hidden", nil)
                                           defaultButton:NMLocalS(@"OK", nil)
                                         alternateButton:showRestore?NMLocalS(@"Restore Now", nil):nil
                                             otherButton:nil
                               informativeTextWithFormat:[self informativeString]];
#pragma clang diagnostic pop
            
            if ([self.delegate respondsToSelector:@selector(statusItemWillBeginModalDialog)]) {
                [self.delegate statusItemWillBeginModalDialog];
            }
            const NSInteger button=[alert runModal];
            if ([self.delegate respondsToSelector:@selector(statusItemDidEndModalDialog)]) {
                [self.delegate statusItemDidEndModalDialog];
            }
            
            if (button==NSAlertAlternateReturn) {
                NMRunAsyncOnMainThread(^{
                    self.iconVisible=YES;
                    if(restoreWindow) {
                        [self openAttachedWindow];
                    }
                });
            }
        }
    }
    
    [self updateImage];
}


- (void)opening
{
    self.menuIsOpen=YES;
    self.canOpenMenu=NO;
    [self updateImage];
}

- (void)closing
{
    self.menuIsOpen=NO;
    [self updateImage];
    self.temporarilyInMenu=NO;
    NMRunAsyncOnMainThreadWithDelay(0.3, ^{ // prevent reopen if reopen occured while menu tracking (dodgy but works)
        self.canOpenMenu=YES;
    });
}

#pragma mark Menu/window did open/close

- (void)menuWillOpen:(NSMenu *)menu
{
    [self opening];
}

- (void)menuDidClose:(NSMenu *)menu
{
    [self closing];
}

#pragma mark Menu handlins

- (void)attachMenu:(NSMenu *)menu
{
	self.statusMenu=menu;
    [self.statusMenu setDelegate:self];
}

#pragma mark Window handling

- (void)attachWindow:(NMStatusBubbleWindow *)window
{
	self.statusWindow=window;
    [self.statusWindow reattach];
    [self.statusWindow setDelegate:self];
    [self.statusWindow prepareFadeAnimation];
}

- (void)openAttachedWindow
{
    [self.statusWindow center];
    [self.statusWindow animateAlphaTo:1.0 duration:0.001];
    [self opening];
    [self.statusWindow makeKeyAndOrderFront:self];
}

- (void)closeAttachedWindow
{
    if (self.menuIsOpen) {
        [self closing];
        [self.statusWindow animateAlphaTo:0 duration:0.15];
    }
}

- (void)closeIfNotSticky
{
    if (!self.sticky) {
        [self closeAttachedWindow];
    }
}

#pragma mark Show the menu or window

- (void)showAttachedMenu:(BOOL)force
{
    if (!self.override && self.ready && (force || (!self.menuIsOpen && self.canOpenMenu))) {
        if (self.statusMenu) {
            [self.statusItem popUpStatusItemMenu:self.statusMenu];
        }
        else if (self.statusWindow) {
            if (self.menuIsOpen) {
                [self closeAttachedWindow];
            }
            else {
                [self openAttachedWindow];
            }
        }
	}
}

- (void)showAttachedMenu
{
	[self showAttachedMenu:NO];
}

#pragma mark Drawing the custom status item

- (void)drawInRect:(NSRect)rect
{
    // draw background
    [self.statusItem drawStatusBarBackgroundInRect:rect withHighlight:self.menuIsOpen];
    
    // get image of correct color
    NSImage *const image=[self statusImageWithColor:^{
        if (!self.ready||!self.enabled) {
            return [[self class] disabledColor];
        }
        else if (self.menuIsOpen) {
            return [[self class] highlightColor];
        }
        else {
            return [[self class] defaultColor];
        }
    }()];
    
    // draw actual image
    [image drawInRect:NMRectRound(NMRectForCenteredBoxInBox([image size], rect.size))
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:1.0];
}

#pragma mark Click actions

- (void)doLeftClickAction
{
    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] postNotificationName:NMStatusItemClickedNotification object:self];
    [self showAttachedMenu:YES];
}

- (void)doRightClickAction
{
    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] postNotificationName:NMStatusItemRightClickedNotification object:self];
	if ([self.delegate respondsToSelector:@selector(statusItemOpenMenuOnRightClick)] && self.delegate.statusItemOpenMenuOnRightClick) {
		[self showAttachedMenu:YES];
	}
}

- (void)doAlternateAction
{
	if ([self.delegate respondsToSelector:@selector(statusItemHideOnAltClick)] && self.delegate.statusItemHideOnAltClick) {
		self.iconVisible=NO;
	}
}

#pragma mark Getting the view and window

- (NSView *)statusItemView
{
    if ([self.statusItem respondsToSelector:@selector(button)]) {
        return self.statusItem.button; // yosemite
    }
    else {
        return [self.statusItem view]; // mavericks and below
    }
}

- (NSWindow *)statusItemWindow
{
    return [[self statusItemView] window];
}

#pragma mark External events

- (void)statusButtonClicked:(id)sender
{
	if ((([[NSApp currentEvent] modifierFlags] & NSControlKeyMask)==NSControlKeyMask) || [[NSApp currentEvent] type] == NSRightMouseDown)
	{
		[self doRightClickAction];
	}
	else if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)==NSAlternateKeyMask) {
		[self doAlternateAction];
	}
	else {
		[self doLeftClickAction];
	}
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    if ([notification object]==self.statusWindow) {
        [self closeIfNotSticky];
    }
}

- (void)userClickedElsewhere
{
    [self closeIfNotSticky];
}

- (void)escapeKeyWasPressed
{
    [self closeIfNotSticky];
}

#pragma mark IconVisible getter/setter

- (BOOL)iconVisible
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:NMStatusItemHideIcon];
}

- (void)setIconVisible:(BOOL)iconVisible
{
    [self willChangeValueForKey:@"iconVisible"];
    [[NSUserDefaults standardUserDefaults] setBool:!iconVisible forKey:NMStatusItemHideIcon];
    [self didChangeValueForKey:@"iconVisible"];
}

#pragma mark Mouse entered and exited

- (void)mouseEntered:(NSEvent *)theEvent
{
    if ([self.delegate respondsToSelector:@selector(mouseEnteredStatusItem)]) {
        [self.delegate mouseEnteredStatusItem];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if ([self.delegate respondsToSelector:@selector(mouseExitedStatusItem)]) {
        [self.delegate mouseExitedStatusItem];
    }    
}

#pragma mark String method

- (NSString *)informativeString
{
    if ([self.delegate respondsToSelector:@selector(statusItemRestoreInstructions)]) {
        return [self.delegate statusItemRestoreInstructions];
    }
    else {
        NSString *appName=[NSRunningApplication currentApplication].localizedName;
        return [NSString stringWithFormat:NMLocalS(@"To restore %@ to the menu bar, click its icon in Launchpad or the Dock, or double-click it in Finder.", nil), appName, appName];
    }
}

@end
