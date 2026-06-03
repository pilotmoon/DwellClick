// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
@class DCAnimationController;

typedef enum {
	DCSymbolStyleEmboss,
	DCSymbolStyleKey,
    DCSymbolStyleKeyHighlight,
	DCSymbolStyleMax
} DCSymbolStyle;

@interface DCSymbolController : NSObject {
	DCAnimationController *animController;
	NSImage *symbolImage;
	NSImage *symbolImageLight;
	NSImage *symbolImageDark;
	NSImage *underlayImage;
	NSImage *underlayImageDark;
	NSImage *underlayImageLight;
}

- (id)initWithAnimationController:(DCAnimationController *)obj;

- (void)clearAll;

- (void)clearSymbol;
- (void)displaySymbolName:(NSString *)name style:(DCSymbolStyle)style;

- (void)clearUnderlay;
- (void)displayUnderlayName:(NSString *)name style:(DCSymbolStyle)style;


@end
