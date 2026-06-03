// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "NMCommander.h"
@class NMKeyCombo;

@interface NMKeyCommander : NSObject <NMCommander> {
    NSMutableDictionary *_commandDict;
    NSArray *_allCommands;
}

+ (NMKeyCommander *)sharedInstance;
- (void)setDefaultKeyCombos;
- (void)setKeyCombosWithDictionary:(NSDictionary *)dict;
- (void)setKeyCombo:(NMKeyCombo *)keyCombo forCommand:(id)command;
- (NMKeyCombo *)keyComboForCommand:(id)command;

@end
