// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
@class DCPrefsController;

@interface DCPrefsSoftwareController : NSViewController {
	DCPrefsController *prefsController;
}
@property (readwrite) DCPrefsController *prefsController;

- (IBAction)aboutApp:(id)sender;
- (IBAction)getHelp:(id)sender;
- (IBAction)checkForUpdates:(id)sender;
@end
