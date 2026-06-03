// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>


@interface NMSugarButton : NSButton {

}
@property (readonly) BOOL mouseIn;
@property (retain) NSColor *backgroundColor;
@property (retain) NSColor *textColor;
@property (retain) NSColor *glowGolor;
@end
