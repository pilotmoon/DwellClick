// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

extern NSString *NMCommanderCutCommand;
extern NSString *NMCommanderCopyCommand;
extern NSString *NMCommanderPasteCommand;

@protocol NMCommander <NSObject>

- (void)performCommand:(id)command;

@end
