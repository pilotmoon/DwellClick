// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMGeometryUtils.h"
#import "NMEscapableItem.h"
#import "NSObject+NMObservePrefs.h"
#import "NMStatusBubbleWindow.h"

extern NSString *NMStatusItemClickedNotification;
extern NSString *NMStatusItemRightClickedNotification;

@protocol NMStatusItemControllerDelegate
@required
@property (readonly) NSImage *statusItemImage;
@property (readonly) NSSize statusItemImageSize;
@optional
@property (readonly) CGFloat statusItemWidth;
@property (readonly) BOOL statusItemHideRestoreButton;
@property (readonly) BOOL statusItemSuppressRestoreInstructions;
@property (readonly) BOOL statusItemOpenMenuOnRightClick;
@property (readonly) BOOL statusItemHideOnAltClick;
@property (readonly) NSString *statusItemRestoreInstructions;
- (void)mouseEnteredStatusItem;
- (void)mouseExitedStatusItem;
- (void)statusItemWillBeginModalDialog;
- (void)statusItemDidEndModalDialog;
@end

@interface NMStatusItemController : NSWindowController <NSWindowDelegate, NSMenuDelegate, NMEscapableItemDelegate>

@property id <NMStatusItemControllerDelegate, NSObject> delegate;
@property BOOL temporarilyInMenu;
@property BOOL enabled;
@property BOOL ready;
@property BOOL override;
@property BOOL sticky;
@property BOOL iconVisible;

+ (NMStatusItemController *)sharedInstance;

- (void)attachMenu:(NSMenu *)menu;
- (void)attachWindow:(NMStatusBubbleWindow *)window;
- (void)showAttachedMenu;
- (NSWindow *)statusItemWindow;
- (void)userClickedElsewhere;

@end
