// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCSymbolController.h"
#import "DCAnimationController.h"
#import "DCConstants.h"
#import "DCCommon.h"
#import "DCEngine.h"
#import "DCAnimationView.h"

static NSShadow *_darkShadow;
static NSShadow *_brightShadow;

@implementation DCSymbolController

+ (void)initialize
{
	if (self==[DCSymbolController class]) {
		_darkShadow=[[NSShadow alloc] init];
		[_darkShadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.5]];
		[_darkShadow setShadowBlurRadius:2];
		[_darkShadow setShadowOffset:NSMakeSize(0, -2)];
		_brightShadow=[[NSShadow alloc] init];
		[_brightShadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
		[_brightShadow setShadowBlurRadius:2];
		[_brightShadow setShadowOffset:NSMakeSize(0, 0)];
	}
}

- (id)initWithAnimationController:(DCAnimationController *)obj
{
	self=[super init];
	if (self) {
		animController=obj;
	}
	return self;
}

- (void)clearAll
{
    [self clearSymbol];
    [self clearUnderlay];
}

- (void)clearSymbol
{
	[animController unregisterDrawBlockForKey:@"symbol"];
}

- (void)renderImageDark:(NSImage *)imageDark light:(NSImage *)imageLight inRect:(NSRect)rect offset:(CGFloat)off highlight:(BOOL)highlight
{
    // get top half rect
    rect.size.height*=0.5;
    rect.origin.y+=rect.size.height;
    
    // inset and move the rect
    CGFloat inset=rect.size.width*0.12;
    rect=NSInsetRect(rect,2*inset,inset);
    rect.origin.y-=(inset-2);
    
    rect.origin.x+=rect.size.width*0.3*off;;
    
    
    [imageDark drawInRect:rect
                 fromRect:NSZeroRect 
                operation:NSCompositeSourceOver
                 fraction:0.4];
    
    // draw dark image with shadow
    rect.origin.y-=0.5;
    [NSGraphicsContext saveGraphicsState];
    [_darkShadow set];
    [imageDark drawInRect:rect
                 fromRect:NSZeroRect 
                operation:NSCompositeSourceOver
                 fraction:0.4];
    [NSGraphicsContext restoreGraphicsState];
    
    // draw light image
    rect.origin.y+=1.0;
    [imageLight drawInRect:rect
                  fromRect:NSZeroRect 
                 operation:NSCompositeSourceOver
                  fraction:highlight?1.0:0.6];
}

- (void)displaySymbolName:(NSString *)name style:(DCSymbolStyle)style
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsSymbolsOn]) {
        return;
    }
    
    NMLogFine(@"Displaying symbol %@", name);
	symbolImage=[NSImage symbolForName:name];
	if (!symbolImage) {
		[self clearSymbol];
	}
	else {
        symbolImageLight=[symbolImage copyWithSize:[symbolImage size] colorTo:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]];
        symbolImageDark=[symbolImage copyWithSize:[symbolImage size] colorTo:[NSColor colorWithDeviceWhite:0.0 alpha:1.0]];
        [animController registerDrawBlockForKey:@"symbol" block:^{
            const NSRect rect=[animController.animView bounds];
            const CGFloat off=[animController isDrawingKey:@"underlay"]?1.0:0.0;
            [self renderImageDark:symbolImageDark light:symbolImageLight inRect:rect offset:off highlight:[DCEngine sharedInstance].lockCurrentClick];
        }];				
	}
}

- (void)clearUnderlay
{
    [animController unregisterDrawBlockForKey:@"underlay"];
}

- (void)displayUnderlayName:(NSString *)name style:(DCSymbolStyle)style
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsSymbolsOn]) {
        return;
    }
    
    NMLogTiny(@"Displaying underlay %@", name);    
    [self clearUnderlay];
    
    underlayImage=[NSImage symbolForName:name];
	if (underlayImage) {
        underlayImageLight=[underlayImage copyWithSize:[underlayImage size] colorTo:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]];
        underlayImageDark=[underlayImage copyWithSize:[underlayImage size] colorTo:[NSColor colorWithDeviceWhite:0.0 alpha:1.0]];
        [animController registerDrawBlockForKey:@"underlay" block:^{
            const NSRect rect=[animController.animView bounds];
            const CGFloat off=[animController isDrawingKey:@"symbol"]?-1.0:0.0;
            [self renderImageDark:underlayImageDark light:underlayImageLight inRect:rect offset:off highlight:style==DCSymbolStyleKeyHighlight];
        }];	
    }
}

@end
