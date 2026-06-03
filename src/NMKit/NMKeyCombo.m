// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMKeyCombo.h"
#import "NMKit.h"
#import <Carbon/Carbon.h>

NSString * const kNMKeyComboKeyChar = @"keyChar";
NSString * const kNMKeyComboKeyCode = @"keyCode";
NSString * const kNMKeyComboModifiers = @"modifiers";

@implementation NMKeyCombo

@synthesize keyChar=_keyChar, keyCode=_keyCode, modifiers=_modifiers;

- (id)initWithKeyChar:(NSString *)keyChar
              keyCode:(NSNumber *)keyCode
            modifiers:(NSNumber *)modifiers
{
    if (self = [super init]) {        
        _keyChar = keyChar;
        _keyCode = keyCode;
        _modifiers = modifiers;        
    }
    return self;
}

- (id)initWithKeyChar:(NSString *)keyChar
              keyCode:(NSNumber *)keyCode
        menuModifiers:(NSNumber *)menuModifiers
{
    /*
     With menu flags, command is on by default.
     1=Shift, 2=Option, 4=Control, 8=!Command
     */
    const NSUInteger menuFlags=[menuModifiers unsignedIntegerValue];
    CGEventFlags flags=0;
    if ((menuFlags&1)==1) {
        flags|=kCGEventFlagMaskShift;
    }
    if ((menuFlags&2)==2) {
        flags|=kCGEventFlagMaskAlternate;
    }
    if ((menuFlags&4)==4) {
        flags|=kCGEventFlagMaskControl;
    }
    if ((menuFlags&8)!=8) {
        flags|=kCGEventFlagMaskCommand;
    }
    return [self initWithKeyChar:keyChar
                         keyCode:keyCode
                       modifiers:@(flags)];
}

- (id)initWithPlistRepresentation:(id)plist
{
    return [self initWithKeyChar:plist[kNMKeyComboKeyChar] 
                         keyCode:plist[kNMKeyComboKeyCode] 
                       modifiers:plist[kNMKeyComboModifiers]];
}

- (BOOL)isEqual:(NMKeyCombo *)other
{
    return ([self.keyChar isEqual:other.keyChar] || [self.keyCode isEqual:other.keyCode]) && [self.modifiers isEqual:other.modifiers];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"keyChar %@, keyCode %@, modifiers %@", self.keyChar, self.keyCode, self.modifiers];
}

- (void)press
{
    const CGKeyCode keyCodeValue=^{
        if (self.keyCode) {
            return [self.keyCode unsignedShortValue];
        }
        else {
            NSNumber *convertedKeyCode=[[NMKeyConverter currentKeyConverter] keyCodeForChar:self.keyChar];
            if (convertedKeyCode) {
                return [convertedKeyCode unsignedShortValue];
            }
        }
        return (CGKeyCode)128;
    }();
    if (keyCodeValue<128&&self.modifiers) {
        NMPostKeyWithFlags(keyCodeValue, [self.modifiers unsignedLongLongValue]);
    }
}

@end