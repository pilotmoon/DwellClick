// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "DCUniqueSelection.h"

@protocol DCSelectionGroupDelegate
- (void)selectionGroup:(DCSelectionGroup *)group willUseSelection:(DCUniqueSelection *)selection withObject:(id)obj;
- (void)selectionGroup:(DCSelectionGroup *)group didUseSelection:(DCUniqueSelection *)selection withObject:(id)obj;
@end

@interface DCSelectionGroup : NSObject {
	id<DCSelectionGroupDelegate> __strong delegate;
	DCUniqueSelection *__strong selectedItem;
}
@property (strong) id<DCSelectionGroupDelegate> delegate;
@property (strong) DCUniqueSelection *selectedItem;
@property (readonly, getter=isNoSelection) BOOL noSelection;

- (DCUniqueSelection *)noSelectionObject;

- (void)setNoSelection;

@end
