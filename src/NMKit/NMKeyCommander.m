// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMKeyCommander.h"
#import "NMKit/NMKit.h"
#import "Carbon/Carbon.h"

@implementation NMKeyCommander

+ (NMKeyCommander *)sharedInstance
{
    static NMKeyCommander *instance=nil;
    if (!instance) {
        instance=[[NMKeyCommander alloc] init];
    }
    return instance;
}

- (id)init
{
    self=[super init];
    if (self) {
        _allCommands=@[NMCommanderCutCommand, NMCommanderCopyCommand, NMCommanderPasteCommand];
        _commandDict=[NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setDefaultKeyCombos
{
    [self setKeyCombo:[[NMKeyCombo alloc] initWithKeyChar:@"X" keyCode:nil modifiers:[NSNumber numberWithUnsignedLongLong:kCGEventFlagMaskCommand]] forCommand:NMCommanderCutCommand];
    [self setKeyCombo:[[NMKeyCombo alloc] initWithKeyChar:@"C" keyCode:nil modifiers:[NSNumber numberWithUnsignedLongLong:kCGEventFlagMaskCommand]] forCommand:NMCommanderCopyCommand];
    [self setKeyCombo:[[NMKeyCombo alloc] initWithKeyChar:@"V" keyCode:nil modifiers:[NSNumber numberWithUnsignedLongLong:kCGEventFlagMaskCommand]] forCommand:NMCommanderPasteCommand];
}

- (void)setKeyCombosWithDictionary:(NSDictionary *)dict
{
    for (id command in _allCommands) {
        [self setKeyCombo:[[NMKeyCombo alloc] initWithPlistRepresentation:dict[command]] forCommand:command];
    }
}

- (void)setKeyCombo:(NMKeyCombo *)keyCombo forCommand:(id)command
{
    if (keyCombo&&command) {
        _commandDict[command] = keyCombo;
    }
}

- (NMKeyCombo *)keyComboForCommand:(id)command
{
    return _commandDict[command];
}

- (void)performCommand:(id)command
{
    [[self keyComboForCommand:command] press];    
}

@end
