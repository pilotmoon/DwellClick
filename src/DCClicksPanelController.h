// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

@class DCEngine;

typedef enum {
	DCPanelStyleVertical=0,
	DCPanelStyleHorizontal
} DCPanelStyle;

@interface DCClicksPanelController : NSWindowController <NSWindowDelegate> {
	DCEngine *_engine;
	NSMutableDictionary *_buttonCache;
    NSButton *_onOffButton;
    NSButton *_lockButton;
    
    NSSize buttonSize;
    CGFloat gap;
    CGFloat end;
    BOOL hide;
    NSTimer *fadeTimer;
    
    CGFloat fullLength;
    NSDate *lastClickTime;
}

- (id)init;
- (IBAction)panelButtonPressed:(id)sender;

@end
