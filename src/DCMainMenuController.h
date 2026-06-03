// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NMSugarButton.h"

/* The main menu is in fact a status menu */
@interface DCMainMenuController : NSObject <NSMenuDelegate> {
	IBOutlet NSMenuItem *onOffItem;
	IBOutlet NSMenu* statusMenu;
    NMSugarButton *__strong buyButton;
    NSMenuItem *__strong buyItem;
}
@property (strong) IBOutlet NSMenuItem *buyItem;
@property (strong) IBOutlet NMSugarButton *buyButton;
@property (readonly) NSString *statusLine;
@property (readonly) BOOL hideBuyLink;

- (IBAction)onlineHelp:(id)sender;
- (IBAction)onlineTutorial:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)buyButton:(id)sender;
- (IBAction)onOffMenuItemAction:(id)sender;
- (IBAction)sendFeedback:(id)sender;
- (void)updateItems;

@end
