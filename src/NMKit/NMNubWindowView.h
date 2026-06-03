// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMNubWindow.h"

@interface NMNubWindowView : NSView {
	NMNubWindow *__unsafe_unretained _ownerWindow;
}
@property (unsafe_unretained) NMNubWindow *ownerWindow;
@end
