// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

typedef NSString *DCCursorType NS_STRING_ENUM;
extern NSString *const DCDebugCursorRecognition;
extern DCCursorType DCCursorTypeArrow;
extern DCCursorType DCCursorTypeBeam;
extern DCCursorType DCCursorTypePointingHand;
extern DCCursorType DCCursorTypeResize;
extern DCCursorType DCCursorTypeOther;

@interface DCCursorInfo : NSObject

@property (readonly) NSString *fingerprintString;
@property (readonly) NSString *asciiArt;
@property (readonly) DCCursorType classification;

+ (DCCursorInfo *)currentCursorInfo;
+ (DCCursorType)currentCursorType;
+ (BOOL)debugCursorRecognition;
- (id)initWithCursor:(NSCursor *)cursor;
- (void)logCursorWithContext:(NSString *)context
                       appId:(NSString *)appId
                        role:(NSString *)role
                       point:(NSPoint)point;

@end
