// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NMUIElement.h"


@interface DCUIState : NSObject {
	NMPoint *mouseFlippedLocation;
	NMUIElement *mouseElement;
	NMUIElement *mouseElementApp;
	NMUIElement *mouseElementMenuBar;
	NSString *mouseElementRole;
	NSSet *mouseElementParents;
	BOOL mouseAppIsBusy;
	NMUIElement *mouseWindow;
	NSString *mouseWindowTitle;
	BOOL mouseWindowIsMain;
	NSString *mouseAppId;
	pid_t mousePid;
	pid_t focusedPid;
	pid_t activePid;
	NSString *activeAppId;
	NSUInteger fingers;
	BOOL tabletProximity;
	BOOL axEnabled;
	CGEventFlags eventFlags;
	NSNumber *cursorHash;
	CGEventFlags modifiersDown;
    BOOL cursorIsVisible;
	BOOL mouseElementIsOwnSliderFallback;
}
@property (readonly) NMPoint *mouseFlippedLocation;
@property (readonly) NMUIElement *mouseElement;
@property (readonly) NMUIElement *mouseElementApp;
@property (readonly) NMUIElement *mouseElementMenuBar;
@property (readonly) NSString *mouseElementRole;
@property (readonly) NSSet *mouseElementParents;
@property (readonly) BOOL mouseAppIsBusy;
@property (readonly) NMUIElement *mouseWindow;
@property (readonly) NSString *mouseWindowTitle;
@property (readonly) BOOL mouseWindowIsMain;
@property (readonly) NSString *mouseAppId;
@property (readonly) pid_t mousePid;
@property (readonly) pid_t focusedPid;
@property (readonly) pid_t activePid;
@property (readonly) NSString *activeAppId;
@property (readonly) NSUInteger fingers;
@property (readonly) BOOL tabletProximity;
@property (readonly) BOOL axEnabled;
@property (readonly) CGEventFlags eventFlags;
@property (readonly) NSNumber *cursorHash;
@property (readonly) CGEventFlags modifiersDown;
@property (readonly) BOOL mouseElementIsOwnSliderFallback;

- (id)initWithFlippedLocation:(NMPoint *)point;
+ (DCUIState *)currentState;

@end
