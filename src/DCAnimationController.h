// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NMBlockUtils.h"
#import "DCClick.h"
@class DCAnimationView;

extern NSString *DCAnimWindowControllerAnimationStoppedNotification;

@interface DCAnimationController : NSObject {
	NSArray *clickFrames;
	NSArray *doubleClickFrames;
	NSArray *tripleClickFrames;
	NSArray *mouseDownFrames;
	NSArray *throbFrames;
	NSArray *mouseUpFrames;
	NSArray *countDownFrames;
	NSArray *currentAnimation;

	NSTimer *timer;	
	NSWindow *window;
	DCAnimationView *animView;
	
	CGFloat boxSide;
	CGFloat speed;
	CGFloat downSpeed;
	
	NSUInteger pos;
	NSUInteger countdownPos;
	NSUInteger countdownHide;
    NSInteger animDirection;
    BOOL throb;
}
@property (readonly) DCAnimationView *animView;
@property (readwrite) BOOL throb;

- (NSUInteger *)posPointer;
- (NSUInteger *)hidePointer;

- (void)doCountdownAnimation;
- (void)stopCountdownAnimation;
- (void)hideCountdownAnimation;

- (void)doFlashAnimationForClickType:(DCClickType)type;
- (void)stopFlashAnimation;

- (void)registerDrawBlockForKey:(id)key block:(NMBasicBlock)block;
- (void)unregisterDrawBlockForKey:(id)key;
- (BOOL)isDrawingKey:(id)key;

@end
