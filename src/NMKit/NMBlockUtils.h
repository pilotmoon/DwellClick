// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

typedef void (^NMBasicBlock)(void);
typedef void (^NMOneParameterBlock)(id obj);
typedef void (^NMArrayEnumeratorBlock)(NSString *type, NSUInteger idx, BOOL *stop);
typedef BOOL (^NMBooleanBlock)(void);
typedef BOOL (^NMEvaluatorBlock)(id obj);
typedef BOOL (^NMBinaryEvaluatorBlock)(id obj1, id obj2);
typedef id (^NMMapBlock)(id obj);

void NMRunAsyncInBackground(NMBasicBlock block);
void NMRunAsyncOnMainThread(NMBasicBlock block);
void NMRunAsyncOnMainThreadWithDelay(NSTimeInterval delay, NMBasicBlock block);
void NMRunSyncOnMainThread(NMBasicBlock block);

/* These are only to be when permanent objets observe permanent objects.
 The observers cannot be removed. sys*/
void NMObserveKeyUsingBlock(NSObject *obj, NSString *key, NMBasicBlock block);
void NMObservePrefsKeysUsingBlock(NSArray *keys, NMBasicBlock block);
void NMObservePrefsKeyUsingBlock(NSString *key, NMBasicBlock block);

@interface NSObject (NMBlocks)
- (void)nm_callBlock;
@end

@interface NSControl (NMBlocks)
- (void)nm_setTargetBlock:(NMBasicBlock) block;
@end

// TODO change to nm and put block last
@interface NSTimer (NMBlocks)
+ (id)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                               block:(NMBasicBlock)block
                             repeats:(BOOL)repeats;
+ (id)timerWithTimeInterval:(NSTimeInterval)timeInterval
                      block:(NMBasicBlock)block
                    repeats:(BOOL)repeats;
@end
