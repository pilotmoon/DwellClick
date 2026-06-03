// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "NMBubbleWindow.h"

@interface NMStatusBubbleWindow : NMBubbleWindow {
@private
    BOOL canBeKey;
    
}
@property BOOL canBeKey;
- (void)reattach;

@end
