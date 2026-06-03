// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "DCEngine.h"

@interface DCEngine (Gubbins) 

@property (assign) BOOL dwellClickOn;
@property (assign) BOOL autoClickOn;

// click count management
- (void)loadClickCounts;
- (void)saveClickCounts;
- (void)resetClickCounts;
- (void)incrementDwellClickCount;
- (void)userPerformedManualClick;

// hot keys
- (void)registerHotKeys;

@end
