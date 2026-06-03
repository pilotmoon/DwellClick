// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCPrefsSoftwareController.h"
#import "DCEngine.h"
#import "NMKit/NMLoginItemsController.h"
#import "NMKit/NMStartAtLogin.h"
#import "NMKit/NMStartAtLogin2024.h"
#import "DCAppDelegate.h"
#import <Sparkle/Sparkle.h>

@implementation DCPrefsSoftwareController
@synthesize prefsController;

- (id)init {
	self = [super initWithNibName:@"PrefsSoftware" bundle:nil];
    return self;
}

- (DCEngine *)engine
{
	return [DCEngine sharedInstance];
}

- (NSObject<NMStartAtLogin> *)loginController
{
    if (@available(macOS 13.0, *)) {
        return [NMStartAtLogin2024 sharedInstance];
    } else {
        return [NMLoginItemsController sharedInstance];
    }
}

- (id)updater
{
	return [(DCAppDelegate *)[NSApp delegate] updater];
}

- (IBAction)aboutApp:(id)sender
{
	[(DCAppDelegate *)[(NSApplication *)NSApp delegate] showAbout:sender];
}

- (IBAction)checkForUpdates:(id)sender
{
	[[(DCAppDelegate *)[NSApp delegate] updaterController] checkForUpdates:sender];
}

- (IBAction)getHelp:(id)sender
{
	[prefsController getHelp:sender];
}



@end
