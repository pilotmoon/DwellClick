// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCLinks.h"
#import "DCMainMenuController.h"
#import "DCPrefsSoftwareController.h"
#import "DCTouchMonitor.h"
#import "DCUtils.h"
#import "NMKit/NMAppUtils.h"

@implementation DCLinks

+ (NSString *)binaryIdentifier
{
    return @"dcsa";
}

+ (NSString *)identifier
{
    return @"dwellclick";
}

+ (NSString *)displayName
{
    return @"DwellClick";
}

+ (void)openBuyLink:(id)sender
{
	[self openLink:@"buy"];
}

+ (void)openSiteLink:(id)sender
{
    [self openLink:@"site"];
}

+ (void)openTutorialLink:(id)sender
{
	BOOL touchpad=DCTouchMonitorMaxFingers>0;
	NSString *addr=[NSString stringWithFormat:@"tutorial/%@", touchpad?@"touch":@"mouse"];
	[self openLink:addr];
}

+ (void)openHelpLink:(id)sender
{
	[self openLink:@"help"];
}

+ (void)openHelpTopic:(NSString *)topic
{
	[self openLink:[NSString stringWithFormat:@"help/topic/%@", topic]];
}

+ (void)openReviewLink:(id)sender
{
	[self openLink:@"review-site"];
}

+ (void)openTagLink:(id)sender
{
	NSInteger tag=[sender tag];
	switch (tag) {
		case 0:
			[self openLink:@"site"];
			break;
		default:
			break;
	}
}

@end
