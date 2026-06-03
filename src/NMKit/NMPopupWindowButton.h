// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMBlockUtils.h"

CGFloat NMPopupButtonHeight();
NSPoint NMPopupButtonTextPosition();
NSPoint NMPopupButtonImageOffset();
NSDictionary *NMPopupButtonTextAttributes();
    
@class NMPopupWindowButton;

@protocol NMPopupWindowButtonDelegate <NSObject>
- (BOOL)isButtonActive:(NMPopupWindowButton *)button;
- (void)makeButtonActive:(NMPopupWindowButton *)button;
- (BOOL)shouldButtonRelinquishActive:(NMPopupWindowButton *)button;
- (void)mouseEnteredButton:(NMPopupWindowButton *)button;
- (void)mouseExitedButton:(NMPopupWindowButton *)button;
@end

@interface NMPopupWindowButton : NSButton {
	BOOL mouseInsideButton;
	NSTrackingArea *ta;
	SEL realAction;
	NSUInteger flashState;
	NSSize renderSize;
    BOOL primaryButton;
    NMBasicBlock buttonBlock;
    BOOL leftmost;
    BOOL rightmost;
    BOOL preserveColor;
    NSString *tip;
    __unsafe_unretained id<NMPopupWindowButtonDelegate> popupButtonDelegate;
    __unsafe_unretained NMPopupWindowButton *nextButton;
    __unsafe_unretained NMPopupWindowButton *prevButton;    
}
@property BOOL mouseInsideButton;
@property (getter=isActiveButton) BOOL activeButton;
@property NSUInteger flashState;
@property NSSize renderSize;
@property BOOL primaryButton;
@property BOOL leftmost;
@property BOOL rightmost;
@property BOOL preserveColor;
@property (copy) NSString *tip;
@property (copy) NMBasicBlock buttonBlock;
@property (unsafe_unretained) NMPopupWindowButton *nextButton;
@property (unsafe_unretained)NMPopupWindowButton *prevButton;
@property (unsafe_unretained)id<NMPopupWindowButtonDelegate> popupButtonDelegate;

- (void)flash;
- (void)updateSize;
- (BOOL)pointInSelf:(NSPoint)unflippedPoint;

+ (NSPoint)imageOffset;
+ (CGFloat)buttonHeight;
+ (NSPoint)textPosition;
+ (NSDictionary *)textAttributes;
+ (CGFloat)nubSize;
+ (void)updateAppearance:(CGFloat)sizeSetting;
+ (void)setLegacyMode:(BOOL)state;
- (void)setTargetBlock:(NMBasicBlock)targetBlock;
@end
