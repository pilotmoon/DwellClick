// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NSWindow+NMAdditions.h"
#import <QuartzCore/QuartzCore.h>

@implementation NSWindow (NMAdditions)

- (void)prepareFadeAnimation
{
    CAAnimation *fadeAnim=[CABasicAnimation animationWithKeyPath:@"alphaValue"];
    [fadeAnim setDelegate:self];
    [self setAnimations:@{@"alphaValue": fadeAnim}];
}

- (void)animateAlphaTo:(CGFloat)alpha duration:(NSTimeInterval)interval
{
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:interval];
	[[self animator] setAlphaValue:alpha];
	[NSAnimationContext endGrouping];	
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
	if (flag) {
        if ([self alphaValue]<0.1f) {
            [self orderOut:self];
        }
        else {
            [self orderFront:self];
        }
	}
}

@end
