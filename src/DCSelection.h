// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCTriggerable.h"

@interface DCSelection : NSObject <DCTriggerable> {
	NSString *name;
	NSUInteger options;
}
@property (readonly) NSString *name;
@property (assign, getter=isSelected) BOOL selected;
@property (assign) NSUInteger options;

- (id)initWithName:(NSString *)aName;
- (void)bindToButton:(NSButton *)button;
- (void)select:(NSScriptCommand*)command;

@end
