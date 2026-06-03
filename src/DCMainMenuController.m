// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCMainMenuController.h"
#import "DCConstants.h"
#import "DCLinks.h"
#import "NMKit/NSImage+NMCopySize.h"
#import "DCEngine+Gubbins.h"
#import "DCAppDelegate.h"
#import "DCUtils.h"
#import "NMKit/NMStatusItemController.h"

@implementation DCMainMenuController
@synthesize buyItem;
@synthesize buyButton;

- (void)updateItems
{
	[onOffItem setState:[DCEngine sharedInstance].dwellClickOn ? NSControlStateValueOn : NSControlStateValueOff];
    if (self.hideBuyLink) {
        NSInteger idx=[statusMenu indexOfItemWithTag:1];
        if (idx>=0) {
            [statusMenu removeItemAtIndex:idx];
        }
        idx=[statusMenu indexOfItemWithTag:2];
        if (idx>=0) {
            [statusMenu removeItemAtIndex:idx];
        }
    }
}

- (id)init
{
	self = [super init];
	[self observePrefsKey:DCPrefsAutoClickOn];
	[((DCAppDelegate *)[(NSApplication *)NSApp delegate]).welcomeWindowController addObserver:self forKeyPath:@"isTryingToTurnOnAx" options:0 context:0];
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self updateItems];
}

- (void)awakeFromNib
{
	[self updateItems];
    buyButton.backgroundColor=DCPurpleColor;
    
	[[NMStatusItemController sharedInstance] attachMenu:statusMenu];
    [statusMenu setDelegate:self];
}

- (void)menuWillOpen:(NSMenu *)menu
{
	[[NMStatusItemController sharedInstance] menuWillOpen:menu];
}

- (void)menuDidClose:(NSMenu *)menu
{
	[[NMStatusItemController sharedInstance] menuDidClose:menu];
	[self updateItems];
}

- (IBAction)onlineHelp:(id)sender
{
	[DCLinks openHelpLink:self];
}

- (IBAction)onlineTutorial:(id)sender
{
	[DCLinks openTutorialLink:self];
}

- (BOOL)pullDown
{
	return NO;
}

- (NSString *)statusLine
{
    return @"";
}

- (BOOL)hideBuyLink
{
	return YES;
}

- (IBAction)buyButton:(id)sender
{
	[DCLinks openBuyLink:self];
}

- (IBAction)showHelp:(id)sender
{
	NSString *path =[[NSBundle mainBundle] pathForResource:@"userguide" ofType:@"html"];
	NMLogInfo(@"help path %@", path);
	NSURL *help = [NSURL fileURLWithPath:path];
	[[NSWorkspace sharedWorkspace] openURL:help];
}

- (IBAction)onOffMenuItemAction:(id)sender
{
	BOOL val=[DCEngine sharedInstance].dwellClickOn;
	[DCEngine sharedInstance].dwellClickOn=!val;
	[self updateItems];
}

- (IBAction)sendFeedback:(id)sender
{
	[DCLinks composeFeedbackEmail];
}

@end
