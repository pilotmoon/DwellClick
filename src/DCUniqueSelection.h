// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCSelection.h"
@class DCSelectionGroup;

@interface DCUniqueSelection : DCSelection {
	DCSelectionGroup *group;
}
@property (readonly) DCSelectionGroup *group;

- (id)initWithName:(NSString *)aName
			 group:(DCSelectionGroup *)aGroup;

@end
