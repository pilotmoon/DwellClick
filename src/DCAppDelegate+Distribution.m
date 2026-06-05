// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCAppDelegate.h"
#import "DCAppDelegate+Distribution.h"

#import "DCConstants.h"
#import "NMKit/NMKit.h"

#import "DCLinks.h"
#import <Sparkle/Sparkle.h>

static NSString *const DCReleaseChannelInfoKey = @"PilotmoonReleaseChannel";
static NSString *const DCReleaseChannelBeta = @"Beta";

@implementation DCAppDelegate (Distribution)

+ (BOOL)isBetaReleaseChannel
{
    NSString *releaseChannel = [[NSBundle mainBundle] objectForInfoDictionaryKey:DCReleaseChannelInfoKey];
    return [releaseChannel isEqualToString:DCReleaseChannelBeta];
}

#pragma mark Main Methods

- (void)distributionInit
{
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
    updaterController = [[SPUStandardUpdaterController alloc] initWithUpdaterDelegate:(id<SPUUpdaterDelegate>)self
                                                                   userDriverDelegate:nil];
}

- (void)distributionVersionUpgrade
{
}

- (void)distributionFirstRun
{
}

- (void)distributionWillFinishLaunching
{
    // do nothing
}

- (void)distributionDidFinishLaunching
{
    NSURL *previousFeedURL = [[updaterController updater] clearFeedURLFromUserDefaults];
    if (previousFeedURL) {
        NMLogInfo(@"Cleared previous Sparkle feed URL override: %@", previousFeedURL);
    }
}

- (void)distributionDidClick
{
}

- (void)showLicenseNoLongerNeededMessage
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"DwellClick is now free"];
    [alert setInformativeText:@"Your license key is no longer needed. Thank you for your previous purchase and support of DwellClick."];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent
{
    NSURL* url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    if ([[url scheme] isEqualToString:@"dwellclick"]&&[[url host] isEqualToString:@"register"]) {
        [self showLicenseNoLongerNeededMessage];
    }
}

- (BOOL)application:(NSApplication *)theApplication
		   openFile:(NSString *)filename
{
    if ([[[filename pathExtension] lowercaseString] isEqualToString:@"dwellclicklicense"]) {
        [self showLicenseNoLongerNeededMessage];
        return YES;
    }
	return YES;
}

- (SPUStandardUpdaterController *)updaterController
{
    return updaterController;
}

- (SPUUpdater *)updater
{
    return [updaterController updater];
}

- (NSString *)feedURLStringForUpdater:(SPUUpdater *)updater
{
    NSString *overrideString = [[NSUserDefaults standardUserDefaults] stringForKey:@"TestFeedURL"];
    if ([overrideString length] > 0) {
        NMLogInfo(@"Using Sparkle test feed URL: %@", overrideString);
        return overrideString;
    }
    return nil;
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)feedParametersForUpdater:(SPUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile
{
    NMLogFine(@"Checking for updates");
    return [NSArray array];
}

- (NSSet<NSString *> *)allowedChannelsForUpdater:(SPUUpdater *)updater
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsBetaUpdates]) {
        NMLogFine(@"Allowing Sparkle beta update channel");
        return [NSSet setWithObject:DCReleaseChannelBeta];
    }
    return [NSSet set];
}

- (void)updater:(SPUUpdater *)updater didFinishLoadingAppcast:(SUAppcast *)appcast
{
    NMLogFine(@"Loaded appcast %@", appcast);
}

@end
