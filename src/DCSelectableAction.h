// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCSelectionGroup.h"

@interface DCSelectableAction : DCUniqueSelection {
	id target;
	SEL selector;
}

- (id)initWithName:(NSString *)aName
			 group:(DCSelectionGroup *)aGroup
			target:(id)aTarget
		  selector:(SEL)aSelector;

- (void)performWithObject:(id)obj;

@end
