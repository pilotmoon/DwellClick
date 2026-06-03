// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMKeyPresser.h"
#import "NMKit/NMBlockUtils.h"
#import "NMKit/NMEventUtils.h"
#import "Carbon/Carbon.h"

@implementation NMKeyPresser

static const NSTimeInterval TIME=0.05;

+ (void)pressCommandX
{
	NMRunAsyncOnMainThreadWithDelay(TIME, ^{
		NMPostCommandAndKey(kVK_ANSI_X);
	});
}

+ (void)pressCommandC
{
	NMRunAsyncOnMainThreadWithDelay(TIME, ^{
		NMPostCommandAndKey(kVK_ANSI_C);
	});
}

+ (void)pressCommandV
{
	NMRunAsyncOnMainThreadWithDelay(TIME, ^{
		NMPostCommandAndKey(kVK_ANSI_V);
	});
}

@end
