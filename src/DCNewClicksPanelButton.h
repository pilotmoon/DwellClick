// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <AppKit/AppKit.h>

@interface DCNewClicksPanelButton : NSButton {
    NSUInteger flashState;
    BOOL mouseInsideButton;
}
@property (readwrite) NSUInteger flashState;
@property (readwrite) BOOL mouseInsideButton;

- (void)flash;
@end
