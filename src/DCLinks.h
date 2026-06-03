// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
#import "NMKit/NMLinks.h"

@interface DCLinks : NMLinks

+ (void)openBuyLink:(id)sender;
+ (void)openTutorialLink:(id)sender;
+ (void)openHelpLink:(id)sender;
+ (void)openSiteLink:(id)sender;
+ (void)openHelpTopic:(NSString *)topic;
+ (void)openReviewLink:(id)sender;
+ (void)openTagLink:(id)sender;

@end
