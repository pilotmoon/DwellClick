// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMKeyConverter.h"

@implementation NMKeyConverter
@synthesize sourceRef=_sourceRef, keyboardLayoutName=_keyboardLayoutName;

+ (NMKeyConverter *)currentKeyConverter
{
    static NMKeyConverter *currentKeyConverter=nil;
    
    // get the current input source
    const TISInputSourceRef sourceRef = TISCopyCurrentASCIICapableKeyboardLayoutInputSource();
    if (sourceRef) {
        if (!currentKeyConverter) {
            currentKeyConverter=[[NMKeyConverter alloc] initWithInputSourceRef:sourceRef];
        }
        else if ([currentKeyConverter sourceRef] != sourceRef) {
            currentKeyConverter=[[NMKeyConverter alloc] initWithInputSourceRef:sourceRef];
        }
        CFRelease(sourceRef);
    }
    
    return currentKeyConverter;
}

- (id)initWithInputSourceRef:(TISInputSourceRef) sourceRef
{
    self=[super init];
    if (self)
    {
        if (!sourceRef)
        {
            NMLogError(@"No keyboard input source.");
            return nil;
        }
        else
        {
            if (sourceRef) {
                CFRetain(sourceRef);
            }
            _sourceRef=sourceRef;        
            _keyboardLayoutName=(__bridge NSString*)TISGetInputSourceProperty(_sourceRef, kTISPropertyLocalizedName);
            _keyboardLayoutData=(__bridge NSData*)TISGetInputSourceProperty(_sourceRef, kTISPropertyUnicodeKeyLayoutData);
            if (!_keyboardLayoutData)
            {
                NMLogError(@"No keyboard layout data. Name: %@", _keyboardLayoutName);
                return nil;
            }
            
            // now build the lookup dictionary
            const int KEYCODE_COUNT=128;
            _charToKeyCode=[NSMutableDictionary dictionaryWithCapacity:KEYCODE_COUNT];
            for (int i=0; i<KEYCODE_COUNT; i++) {
                NSString *c=[self charForKeyCode:i];
                if (c) {
                    ((NSMutableDictionary *)_charToKeyCode)[c] = @(i);
                }
            }            
            NMLogFine(@"Created KeyConverter with layout name %@", _keyboardLayoutName);            
        }
    }

    return self;
}

- (void)dealloc
{
    if (_sourceRef) {
        CFRelease(_sourceRef);
    }
}

- (NSString *)charForKeyCode:(CGKeyCode)keyCode
{
    NSString *result=nil;
    
    const int MAX_STRING_LENGTH=4;
    UniChar unicodeString[MAX_STRING_LENGTH];
    UniCharCount actualStringLength=0;
    UInt32 deadKeyState=0;
    
    UCKeyTranslate((UCKeyboardLayout *)[_keyboardLayoutData bytes], 
                   keyCode, 
                   kUCKeyActionDisplay, 
                   0, 
                   LMGetKbdType(), 
                   kUCKeyTranslateNoDeadKeysBit, 
                   &deadKeyState, 
                   MAX_STRING_LENGTH, 
                   &actualStringLength, 
                   unicodeString);
    
    if (actualStringLength==1) {
        result=[[NSString stringWithCharacters:unicodeString length:1] uppercaseString];          
    }

    return result;
}

- (NSNumber *)keyCodeForChar:(NSString *)character
{
    if ([self.keyboardLayoutName isEqualToString:@"Dvorak - Qwerty ⌘"]) {
        if ([character isEqualToString:@"X"]) {
            return @7;
        }
        else if ([character isEqualToString:@"C"]) {
            return @8;            
        }
        else if ([character isEqualToString:@"V"]) {
            return @9;            
        }
    }    
    NSNumber *result=nil;
    result=_charToKeyCode[character];
    NMLogFine(@"got %@ for char %@ from dict", result, character);
    return result;
}

@end
