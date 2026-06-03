// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMBlockUtils.h"

#pragma mark Run blocks

void NMRunAsyncInBackground(NMBasicBlock block)
{
	dispatch_async(dispatch_get_global_queue(0,0), block);
}

void NMRunAsyncOnMainThread(NMBasicBlock block)
{
	dispatch_async(dispatch_get_main_queue(), block);
}

void NMRunAsyncOnMainThreadWithDelay(NSTimeInterval delay, NMBasicBlock block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*delay), dispatch_get_main_queue(), block);
}

void NMRunSyncOnMainThread(NMBasicBlock block)
{
	dispatch_sync(dispatch_get_main_queue(), block);
}

#pragma mark Observe prefs

@interface NMBlockObserver : NSObject
@property (copy) NMBasicBlock block;
@end

@implementation NMBlockObserver

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.block();
}

@end

static void NMObserveKeysWithPrefixUsingBlock(NSObject *obj, NSArray *keys, NSString* prefix, NMBasicBlock block)
{
    NMBlockObserver *const observer=[[NMBlockObserver alloc] init];
    CFRetain((__bridge CFTypeRef)observer);
    observer.block=block;
    
    for (NSString *key in keys) {
        [obj addObserver:observer forKeyPath:[prefix stringByAppendingString:key] options:0 context:nil];
    }

    block();
}

void NMObserveKeyUsingBlock(NSObject *obj, NSString *key, NMBasicBlock block)
{
    NMObserveKeysWithPrefixUsingBlock(obj, @[key], @"", block);
}

void NMObservePrefsKeysUsingBlock(NSArray *keys, NMBasicBlock block)
{
    NMObserveKeysWithPrefixUsingBlock([NSUserDefaultsController sharedUserDefaultsController], keys, @"values.", block);
}

void NMObservePrefsKeyUsingBlock(NSString *key, NMBasicBlock block)
{
    NMObservePrefsKeysUsingBlock(@[key], block);
}

#pragma mark Block as action target

@implementation NSObject (NMBlocks)

- (void)nm_callBlock
{
    ((NMBasicBlock)self)();
}

@end

@implementation NSControl (NMBlocks)

- (void)nm_setTargetBlock:(NMBasicBlock) block
{
	[self setTarget:block];
	[self setAction:@selector(nm_callBlock)];
}

@end

#pragma mark NSTimer

@implementation NSTimer (NMBlocks)

+ (id)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                               block:(NMBasicBlock)block
                             repeats:(BOOL)repeats
{
    return [self scheduledTimerWithTimeInterval:timeInterval
                                         target:[block copy]
                                       selector:@selector(nm_callBlock)
                                       userInfo:nil
                                        repeats:repeats];
}

+ (id)timerWithTimeInterval:(NSTimeInterval)timeInterval
                      block:(NMBasicBlock)block
                    repeats:(BOOL)repeats
{
    return [self timerWithTimeInterval:timeInterval
                                target:[block copy]
                              selector:@selector(nm_callBlock)
                              userInfo:nil
                               repeats:repeats];
}

@end

