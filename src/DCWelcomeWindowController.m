// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCWelcomeWindowController.h"

#import "DCAppDelegate.h"
#import "DCClickMachine.h"
#import "DCConstants.h"
#import "DCEngine+Gubbins.h"
#import "DCLinks.h"
#import "DCUtils.h"

#import "NMKit/NMAppMonitor.h"
#import "NMKit/NMLoginItemsController.h"
#import "NMKit/NMStartAtLogin.h"
#import "NMKit/NMStartAtLogin2024.h"
#import "NMKit/NMStatusBubbleWindow.h"
#import "NMKit/NMUniversalAccessHelper.h"

@interface DCWelcomeWindowController ()
- (NSObject<NMStartAtLogin> *)loginController;
@end

@implementation DCWelcomeWindowController
@synthesize waiting, isTryingToTurnOnAx, window;

- (NSObject<NMStartAtLogin> *)loginController
{
    if (@available(macOS 13.0, *)) {
        return [NMStartAtLogin2024 sharedInstance];
    } else {
        return [NMLoginItemsController sharedInstance];
    }
}

- (id) init {
    self = [super init];
	if (self)
	{
		window=[[NMStatusBubbleWindow alloc] init];
		[window setDelegate:self];
		nib=[[NSNib alloc] initWithNibNamed:@"Welcome" bundle:nil];
        
        NSArray *tloTemp=nil;
        if (![nib instantiateWithOwner:self topLevelObjects:&tloTemp]) return nil;
        topLevelObjects=tloTemp;
        
		[startupSetting setState:NSOffState];
		[NMAppMonitor sharedInstance];
		[[NMUniversalAccessHelper sharedInstance] addObserver:self forKeyPath:@"axEnabled" options:0 context:0];
	}
	return self;
}

- (void)doLoading
{
	[progress startAnimation:self];
	[window setView:waitView];
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:self];	
}

- (void)doWelcome
{
	[progress stopAnimation:self];
	[window setView:welcomeView];
	[DCEngine sharedInstance].override=YES;
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:self];		
    [window bringAttentionToWindow];
}

- (void)doWarning
{
	[window setView:axWarningView];
	[window makeKeyAndOrderFront:self];
	[NSApp activateIgnoringOtherApps:YES];
}


- (void)doAX
{
	self.isTryingToTurnOnAx=YES;
	[self doAXManual];
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:self];
}

- (void)doTutorial
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:DCPrefsHasRunTutorial];
	[window setView:tutorialView];
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:self];
}

- (void)doAXManual
{
    [window setView:axViewMav];
}

- (void)doAX2mav
{
	[window setView:axView2Mav];
}

- (void)doAXDone
{
	[window setView:axViewDone];
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:self];
}

- (void)donePopup
{
	[window close];
	[window setView:nil];
}

- (IBAction)handleButton:(id)sender
{
	switch ([sender tag]) {
		case 1:
			if ([startupSetting state]==NSOnState) {
				self.loginController.startAtLogin=YES;
			}
			[DCEngine sharedInstance].override=NO;
			if ([NMUniversalAccessHelper sharedInstance].axEnabled) {
				[self doTutorial];
				[DCEngine sharedInstance].dwellClickOn=YES;
			}
			else {
				[self doAX];
			}
			break;
			
		case 2:
			[DCLinks openTutorialLink:self];
			[self donePopup];
			break;
			
		case 3:
			[self donePopup];
			break;
			
		case 4:
		{
            [NMUniversalAccessHelper enableUniversalAccess];
            [self doAX2mav];
			
			break;
			
		}
		
		case 5:
			[self doAX];
			break;
			
		case 6:
			[self donePopup];
			[DCEngine sharedInstance].dwellClickOn=YES;
			break;
			
		case 9:
			[self doWarning];
			break;
			
		default:
			break;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([NMUniversalAccessHelper sharedInstance].axEnabled) {
		if ([window contentView]==axWarningView) {
			[window close];
		}		
		if (self.isTryingToTurnOnAx) {
			self.isTryingToTurnOnAx=NO;
			[self doAXDone];
		}
	}
	else {
		
	}
}

@end
