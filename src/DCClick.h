// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCSelectableAction.h"

@class NMPoint;

typedef enum {
	DCClickTypeNone=0,
	DCClickTypeSingle,
	DCClickTypeDouble,
	DCClickTypeDragBegin,
	DCClickTypeDragEnd,
	DCClickTypeMouseUp,
	DCClickTypeTriple,
	DCClickTypePopupButton,
	DCClickTypeDragLockSound,
	DCClickTypeHoverOn,    
	DCClickTypeMax
} DCClickType;

@interface DCClick : DCSelectableAction {
	NSImage *icon;
	DCClick *__strong drop;
	DCClickType type;
}
@property (readonly) NSImage *icon;
@property (strong) DCClick *drop;
@property (readonly) DCClickType type;
@property (readonly, getter=isComplete) BOOL complete;
@property (readonly, getter=isBeginning) BOOL beginning;

- (id)initWithTarget:(id)aTarget
			selector:(SEL)anAction
	  group:(DCSelectionGroup *)anActionSelector
				name:(NSString *)aName
				type:(DCClickType)aType
				drop:(DCClick *)aDrop;

- (void)setModifierForThisClick;


@end
