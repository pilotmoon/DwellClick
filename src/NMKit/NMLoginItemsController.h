// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "NMStartAtLogin.h"

@interface NMLoginItemsController : NSObject<NMStartAtLogin> {
#ifdef __OBJC_GC__    
	__strong 
#endif
    LSSharedFileListRef loginItems;
}

// "Start at Login" property to be bound to by prefs checkbox.
@property BOOL startAtLogin;

+ (NMLoginItemsController *)sharedInstance;
- (void)cleanup;
- (BOOL)startAtLoginWithURL:(NSURL *)bundleUrl;
- (void)setStartAtLogin:(BOOL)enabled withURL:(NSURL *)bundleUrl;
- (BOOL)startAtLogin;
- (void)setStartAtLogin:(BOOL)enabled;

@end
