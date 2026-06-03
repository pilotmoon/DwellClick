// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

@interface NMKeyCombo : NSObject {
    NSString *_keyChar;
    NSNumber *_keyCode;
    NSNumber *_modifiers;
}

@property (nonatomic, readonly) NSString *keyChar;
@property (nonatomic, readonly) NSNumber *keyCode;
@property (nonatomic, readonly) NSNumber *modifiers;

/*
 Init from virtual keycode and modifiers mask.
 */
- (id)initWithKeyChar:(NSString *)keyChar
              keyCode:(NSNumber *)keyCode
            modifiers:(NSNumber *)modifiers;

/*
 Init from AXAPI Menu parameters.
 */
- (id)initWithKeyChar:(NSString *)keyChar
              keyCode:(NSNumber *)keyCode
        menuModifiers:(NSNumber *)menuModifiers;

- (id)initWithPlistRepresentation:(id)thePlist;

- (BOOL)isEqual:(NMKeyCombo *)theCombo;

- (void)press;

@end