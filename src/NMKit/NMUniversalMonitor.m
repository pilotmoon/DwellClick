// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMUniversalMonitor.h"
#import "NMKit/NMKit.h"

@implementation NMUniversalMonitor

- (id)initWithMask:(NSEventMask)mask andBlock:(NMBasicBlock)block
{
    self=[super init];
    if (self) {
        if (block) {
            global=[NSEvent addGlobalMonitorForEventsMatchingMask:mask handler:^(NSEvent *event) { block(); }];
            local=[NSEvent addLocalMonitorForEventsMatchingMask:mask handler:^NSEvent *(NSEvent *event) { block(); return event; }];            
        }
    }
    return self;
}

+ (id)monitorWithMask:(NSEventMask)mask andBlock:(NMBasicBlock)block
{
    return [[[self class] alloc] initWithMask:mask andBlock:block];
}

+ (id)housekeepingMonitorWithImmediateRun:(BOOL)immediate repeats:(NSUInteger)repeats interval:(NSTimeInterval)interval block:(NMBasicBlock)block
{
    __block NSTimer *housekeepingTimer=nil;
    return [self monitorWithMask:NSKeyDownMask|NSKeyUpMask|NSLeftMouseDownMask|NSLeftMouseUpMask andBlock:^{
        if (![housekeepingTimer isValid]) {
            if (immediate&&block) {
                NMRunAsyncOnMainThread(block);
            }
            __block NSInteger count=0;
            housekeepingTimer=[NSTimer scheduledTimerWithTimeInterval:interval block:^{
                if (++count>repeats) {
                    [housekeepingTimer invalidate];
                    housekeepingTimer=nil;
                }
                else {
                    if (block) block();
                }                
            } repeats:YES];
        }
    }];
}

+ (id)fastHousekeepingMonitorWithBlock:(NMBasicBlock)block
{
    return [self housekeepingMonitorWithImmediateRun:NO repeats:5 interval:0.25 block:block];
}

- (void)stopMonitor
{
    if (global) {
        [NSEvent removeMonitor:global];
        global=nil;
    }
    if (local) {
        [NSEvent removeMonitor:local];
        local=nil;
    }
}

- (BOOL)isValid
{
    return global&&local;
}

- (void)dealloc
{
    [self stopMonitor];
}

@end
