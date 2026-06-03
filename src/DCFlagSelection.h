// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCSelection.h"

@class DCFlagGroup;

@interface DCFlagSelection : DCSelection {
	DCFlagGroup *group;
	CGEventFlags mask;
}
@property (readonly) DCFlagGroup *group;

- (id)initWithName:(NSString *)aName
			  mask:(CGEventFlags)aMask
			 group:(DCFlagGroup *)aGroup;

@end
