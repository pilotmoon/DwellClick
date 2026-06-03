// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCStatusItemDelegate.h"
#import "NMKit/NMUniversalAccessHelper.h"
#import "DCEngine+Gubbins.h"
#import "DCConstants.h"

@implementation DCStatusItemDelegate

- (NSImage *)statusItemImage
{
    return [NSImage imageNamed:@"DCIconStatus.png"];
}

- (NSSize)statusItemImageSize
{
    return NSMakeSize(14, 19);
}

- (CGFloat)statusItemWidth
{
    return 21.0;
}

- (NSColor *)statusItemGlowColor
{
    return [NSColor purpleColor];
}

- (BOOL)statusItemHideOnAltClick
{
    return YES;
}

- (BOOL)statusItemOpenMenuOnRightClick
{
    return YES;
}

- (void)mouseEnteredStatusItem
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsStatusItemHover]) {
        if (![DCEngine sharedInstance].mouseInActivationArea) {
            [DCEngine sharedInstance].mouseInActivationArea=YES;
        }
    }
}

- (void)mouseExitedStatusItem
{
    if ([DCEngine sharedInstance].mouseInActivationArea) {
        [DCEngine sharedInstance].mouseInActivationArea=NO;
    }    
}

@end
