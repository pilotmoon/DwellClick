// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "NMKit/NMBlockUtils.h"

@interface NMUniversalMonitor : NSObject {
    id local;
    id global;
}

- (id)initWithMask:(NSEventMask)mask andBlock:(NMBasicBlock)block;
- (void)stopMonitor;
- (BOOL)isValid;

+ (id)monitorWithMask:(NSEventMask)mask andBlock:(NMBasicBlock)block;
+ (id)housekeepingMonitorWithImmediateRun:(BOOL)immediate repeats:(NSUInteger)repeats interval:(NSTimeInterval)interval block:(NMBasicBlock)block;
+ (id)fastHousekeepingMonitorWithBlock:(NMBasicBlock)block;

@end
