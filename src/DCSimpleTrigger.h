// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCTriggerable.h"

@interface DCSimpleTrigger : NSObject <DCTriggerable> {
	NSString *name;
	id target;
	SEL selector;
}

@property (readonly) NSString *name;

- (id)initWithName:(NSString *)aName
			target:(id)aTarget
		  selector:(SEL)aSelector;

@end
