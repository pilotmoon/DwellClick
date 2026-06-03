// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

@interface NMSimplifiedCursor : NSObject {
    NSUInteger _pixelsPerRow;
    NSUInteger _numberOfRows;
    NSData *_data;
}
- (id)initWithAsciiArt:(NSString *)asciiArt;
- (id)initWithImage:(NSImage *)image;
@property (readonly) NSUInteger pixelsPerRow;
@property (readonly) NSUInteger numberOfRows;
@property (readonly) NSData *data;
- (NSString *)asciiArt;
- (BOOL)isBeam;
- (BOOL)isArrow;
- (BOOL)isBlank;
@end

@interface NSCursor (NMCursorUtils)
- (NSUInteger)superFastHash;
- (NMSimplifiedCursor *)simplifiedCursor;
- (NSNumber *)standardHashNum;
+ (NSNumber *)standardArrowPlaceholder;
+ (NSNumber *)standardBeamPlaceholder;
+ (NSNumber *)standardBlankPlaceholder;
@end

