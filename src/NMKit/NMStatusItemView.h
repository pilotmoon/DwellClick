// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

@class NMStatusItemController;

@protocol NMStatusItemViewDelegate
@required
- (void)drawInRect:(NSRect)rect;
- (void)doLeftClickAction;
- (void)doRightClickAction;
- (void)doAlternateAction;
@end

@interface NMStatusItemView : NSButton {
	__unsafe_unretained NMStatusItemController *_controller;
}

- (id)initWithFrame:(NSRect)frame controller:(NMStatusItemController *)controller;

@end
