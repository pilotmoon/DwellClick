// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

@interface NMUIElementHelper : NSObject {
	NSConditionLock *conditionLock;
	NSPoint param;
	AXUIElementRef result;	
	AXError lastError;
}

+ (AXUIElementRef)systemWideElement;
- (AXError) lastError;
- (AXUIElementRef)elementAtUnflippedLocation:(NSPoint) point;
- (AXUIElementRef)elementAtUnflippedLocation:(NSPoint) point
									 timeout:(NSTimeInterval)timeout;

@end
