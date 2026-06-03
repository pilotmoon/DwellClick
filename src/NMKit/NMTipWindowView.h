// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

@interface NMTipWindowView : NSView {
    NSFont *_font;
    NSString *_text;
}
@property (retain) NSFont *font;
@property (retain) NSString *text;
@end
