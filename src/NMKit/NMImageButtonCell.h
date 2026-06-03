// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>


@interface NMImageButtonCell : NSButtonCell {
    NSColor *_tintColor;
}
@property (retain) NSColor *tintColor;

@end
