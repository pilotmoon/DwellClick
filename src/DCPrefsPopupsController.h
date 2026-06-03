// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NMPopupWindow.h"
#import "NMKit/NMPopupWindowBackgroundView.h"
#import "NMKit/NMPopupWindowBorderView.h"

@class DCPrefsController;

@interface DCPrefsPopupsController : NSViewController {
	DCPrefsController *prefsController;

	// preview box
	IBOutlet NSView *previewBox;
	NSMutableDictionary *proxyButtonCache;
	NMPopupWindow *proxyWindow;
	NMPopupWindowBackgroundView *previewBackgroundView;
	NMPopupWindowBorderView *previewBorderView;
}
@property (readwrite) DCPrefsController *prefsController;
@property (readonly) NSString *shortcutString;

- (IBAction)getHelp:(id)sender;
@end
