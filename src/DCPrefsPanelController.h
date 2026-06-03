// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
@class DCPrefsController;

@interface DCPrefsPanelController : NSViewController {
	DCPrefsController *prefsController;
    NSBox *__strong buttonBox;
    NSArray *buttonOrder;
    NSArray *checkBoxArray;
    NSArray *imageArray;
}
@property (strong) IBOutlet NSBox *buttonBox;
@property (readwrite) DCPrefsController *prefsController;

- (IBAction)getHelp:(id)sender;

@end    
