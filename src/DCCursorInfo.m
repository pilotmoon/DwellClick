// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCCursorInfo.h"
#import "NMKit/NMCursorFingerprint.h"
#import "NMKit/NMConfigUtils.h"
#import "NMKit/NMCoreUtils.h"
#import "NMKit/NMLog.h"

NSString *const DCDebugCursorRecognition = @"DCDebugCursorRecognition";
DCCursorType DCCursorTypeArrow = @"arrow";
DCCursorType DCCursorTypeBeam = @"beam";
DCCursorType DCCursorTypePointingHand = @"pointing-hand";
DCCursorType DCCursorTypeResize = @"resize";
DCCursorType DCCursorTypeOther = @"other";

static NSString *const DCCursorClassificationsConfigKey = @"CursorClassifications";
static NSMutableDictionary<NMCursorFingerprint *, DCCursorType> *_classifications;

static DCCursorType _classify(NMCursorFingerprint *fingerprint)
{
    if (!fingerprint) {
        return nil;
    }

    __block DCCursorType result=_classifications[fingerprint];
    if (!result) {
        [_classifications enumerateKeysAndObjectsUsingBlock:^(NMCursorFingerprint *key, DCCursorType type, BOOL *stop) {
            if ([fingerprint fuzzyMatchFingerprint:key]) {
                result=type;
                *stop=YES;
            }
        }];
        if (result) {
            _classifications[fingerprint]=result;
        }
    }
    return result;
}

static void _saveClassification(NSCursor *cursor, DCCursorType type)
{
    NMCursorFingerprint *fp=[NMCursorFingerprint fingerprintWithCursor:cursor];
    [_classifications safeSetObject:type forKey:fp];
}

static void _saveCursors(NSArray<NSCursor *> *cursors, DCCursorType type)
{
    for (NSCursor *cursor in cursors) {
        _saveClassification(cursor, type);
    }
}

@implementation DCCursorInfo

+ (void)classifyStandardCursors
{
    [@{
        DCCursorTypeArrow : @[ [NSCursor arrowCursor] ],
        DCCursorTypeBeam : @[ [NSCursor IBeamCursor],
                              [NSCursor IBeamCursorForVerticalLayout] ],
        DCCursorTypePointingHand : @[ [NSCursor pointingHandCursor] ],
        DCCursorTypeResize : @[ [NSCursor resizeUpCursor],
                                [NSCursor resizeDownCursor],
                                [NSCursor resizeLeftCursor],
                                [NSCursor resizeRightCursor],
                                [NSCursor resizeUpDownCursor],
                                [NSCursor resizeLeftRightCursor] ],
        DCCursorTypeOther : @[ [NSCursor crosshairCursor],
                               [NSCursor openHandCursor],
                               [NSCursor closedHandCursor],
                               [NSCursor disappearingItemCursor],
                               [NSCursor operationNotAllowedCursor],
                               [NSCursor dragLinkCursor],
                               [NSCursor dragCopyCursor],
                               [NSCursor contextualMenuCursor] ],
    } enumerateKeysAndObjectsUsingBlock:^(DCCursorType type, NSArray<NSCursor *> *cursors, BOOL *stop) {
        _saveCursors(cursors, type);
    }];

    if (@available(macOS 15.0, *)) {
        _saveCursors(@[
            [NSCursor columnResizeCursor],
            [NSCursor columnResizeCursorInDirections:NSHorizontalDirectionsLeft],
            [NSCursor columnResizeCursorInDirections:NSHorizontalDirectionsRight],
            [NSCursor columnResizeCursorInDirections:NSHorizontalDirectionsAll],
            [NSCursor rowResizeCursor],
            [NSCursor rowResizeCursorInDirections:NSVerticalDirectionsUp],
            [NSCursor rowResizeCursorInDirections:NSVerticalDirectionsDown],
            [NSCursor rowResizeCursorInDirections:NSVerticalDirectionsAll],
        ], DCCursorTypeResize);

        NSArray<NSNumber *> *positions=@[
            @(NSCursorFrameResizePositionTop),
            @(NSCursorFrameResizePositionLeft),
            @(NSCursorFrameResizePositionBottom),
            @(NSCursorFrameResizePositionRight),
            @(NSCursorFrameResizePositionTopLeft),
            @(NSCursorFrameResizePositionTopRight),
            @(NSCursorFrameResizePositionBottomLeft),
            @(NSCursorFrameResizePositionBottomRight),
        ];
        NSArray<NSNumber *> *directions=@[
            @(NSCursorFrameResizeDirectionsInward),
            @(NSCursorFrameResizeDirectionsOutward),
            @(NSCursorFrameResizeDirectionsAll),
        ];
        for (NSNumber *position in positions) {
            for (NSNumber *direction in directions) {
                _saveClassification([NSCursor frameResizeCursorFromPosition:[position unsignedIntegerValue]
                                                               inDirections:[direction unsignedIntegerValue]],
                                    DCCursorTypeResize);
            }
        }
    }
}

+ (void)initialize
{
    if (self == [DCCursorInfo class]) {
        _classifications=[NSMutableDictionary dictionary];

        NSDictionary *presetCursors=[NSDictionary dictionaryWithConfigName:DCCursorClassificationsConfigKey];
        [presetCursors enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            NSString *type=[value componentsSeparatedByString:@"/"][0];
            NMCursorFingerprint *fp=[[NMCursorFingerprint alloc] initWithString:key];
            if (fp) {
                _classifications[fp]=type;
            }
        }];

        [self classifyStandardCursors];
    }
}

+ (DCCursorInfo *)currentCursorInfo
{
    return [[DCCursorInfo alloc] initWithCursor:[NSCursor currentSystemCursor]];
}

+ (DCCursorType)currentCursorType
{
    return [[self currentCursorInfo] classification];
}

+ (BOOL)debugCursorRecognition
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DCDebugCursorRecognition];
}

- (id)initWithCursor:(NSCursor *)cursor
{
    self=[super init];
    if (self) {
        NMCursorFingerprint *fingerprint=[NMCursorFingerprint fingerprintWithCursor:cursor];
        _fingerprintString=[fingerprint description];
        _asciiArt=[fingerprint asciiArt];
        _classification=_classify(fingerprint);
        if (![DCCursorInfo debugCursorRecognition]) {
            NMLogTiny(@"Cursor classification is %@", _classification ?: @"unknown");
        }
    }
    return self;
}

- (void)logCursorWithContext:(NSString *)context
                       appId:(NSString *)appId
                        role:(NSString *)role
                       point:(NSPoint)point
{
    if (![DCCursorInfo debugCursorRecognition]) {
        return;
    }

    NSString *type=self.classification ?: @"unknown";
    NSString *fingerprint=self.fingerprintString ?: @"(none)";
    NSString *plistType=[self.classification isEqualToString:DCCursorTypeResize] ? self.classification : DCCursorTypeResize;
    NMLogInfo(@"CURSOR %@ type=%@ fingerprint=%@ app=%@ role=%@ point=%@",
              context ?: @"snapshot",
              type,
              fingerprint,
              appId ?: @"(unknown)",
              role ?: @"(unknown)",
              NSStringFromPoint(point));

    NMLogInfo(@"CURSOR %@ suggested Config.plist snippet:\n<key>%@</key>\n<string>%@</string>",
              context ?: @"snapshot",
              fingerprint,
              plistType);

    if (self.asciiArt) {
        NMLogInfo(@"CURSOR %@ ascii:\n%@", context ?: @"snapshot", self.asciiArt);
    }
}

@end
