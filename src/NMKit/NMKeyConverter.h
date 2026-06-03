// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#include <Carbon/Carbon.h>

@interface NMKeyConverter : NSObject {
#ifdef __OBJC_GC__    
	__strong 
#endif
    TISInputSourceRef _sourceRef;
    NSString *_keyboardLayoutName;
    NSData *_keyboardLayoutData;
    NSDictionary *_charToKeyCode;
}

@property (nonatomic, readonly) TISInputSourceRef sourceRef;
@property (readonly) NSString *keyboardLayoutName;

+ (NMKeyConverter *)currentKeyConverter;
- (id)initWithInputSourceRef:(TISInputSourceRef) sourceRef;

- (NSString *)charForKeyCode:(CGKeyCode)keyCode;
- (NSNumber *)keyCodeForChar:(NSString *)character;
    
@end
