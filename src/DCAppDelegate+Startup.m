// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCAppDelegate+Startup.h"
#import "DCConstants.h"
#import "DCUtils.h"
#import "DCLinks.h"
#import "NMKit/NMKit.h"

static NSString *PMUsageHasRunBefore = @"PMUsageHasRunBefore";

#define PREFS_EXT @"plist"
#define CURRENT_MAJOR_VER 344

@implementation DCAppDelegate (Startup)

+ (BOOL)isBetaExpired
{
#ifdef DC_BETA
	NSDate *expireDate=DCExpireDate(DCBetaDays);
	NMLogInfo(@"expire date: %@", expireDate);
	if ([expireDate earlierDate:[NSDate date]] == expireDate)
	{
		NSInteger button=NSRunAlertPanel(@"Beta Expired",
						@"This time-limited beta version has expired.",
						@"Visit Website", @"Quit", nil);
		if (button==NSAlertDefaultReturn) {
			[DCLinks openSiteLink:self];
			[NSThread sleepForTimeInterval:0.5];
		}
		return YES;
	}
#endif
	return NO;
}

+ (BOOL)isAlreadyRunning;
{
	NSRunningApplication *app=nil;
	for (app in [[NSWorkspace sharedWorkspace] runningApplications])
    {
        // if not this app
		if (![app isEqual:[NSRunningApplication currentApplication]])
        {
            // if app is instance of this app
			if ([[app.bundleIdentifier lowercaseString] isEqualToString:[DCProductID() lowercaseString]])
            {
				break;
			}			
		}
	}
	
    NMLogInfo(@"APP %@", app);
    // if we found another copy running
	if (app)
    { 
        // just silently quit the other, and update the start at login
        if ([app terminate])
        {
            NSURL *url=[app bundleURL];
            if ([[NMLoginItemsController sharedInstance] startAtLoginWithURL:url]) {
                [[NMLoginItemsController sharedInstance] setStartAtLogin:NO withURL:url];
                [[NMLoginItemsController sharedInstance] setStartAtLogin:YES withURL:[[NSBundle mainBundle] bundleURL]];
            }
        }
        else {
            NSString *thisAppName=[NSRunningApplication currentApplication].localizedName;
            NSString *otherAppName=app.localizedName;
            NSString *otherCopyText=[thisAppName isEqualToString:otherAppName]?@"another copy":otherAppName;
            NSAlert *alert=[NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ is already running.", otherAppName]
                                           defaultButton:@"Quit"
                                         alternateButton:nil
                                             otherButton:nil
                               informativeTextWithFormat:@"%@ cannot start while %@ is running.", thisAppName, otherCopyText];
            [alert runModal];
            return YES;
        }
	}
	return NO;
}

- (BOOL)testVersionUpgraded
{
	BOOL isUpgrade=NO;
	
	// get current ver
	NSString *currentVerString=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSInteger currentVer=[currentVerString integerValue];
	if (currentVer<=0) {
		NMLogInfo(@"current version is bad.");
		return NO;
	}
	
	// get old ver
	NSString *oldVerString=[[NSUserDefaults standardUserDefaults] objectForKey:DCPrefsAppVersion];
	NSInteger oldVer=[oldVerString integerValue];
	if (oldVer<=0) {
		NMLogInfo(@"no version found. assuming it is an upgrade.");
		isUpgrade=YES;
	}
	else if (currentVer>oldVer) {
        if (oldVer<CURRENT_MAJOR_VER) {
            isUpgrade=YES;
        }
	}
	
	// set current version
	[[NSUserDefaults standardUserDefaults] setObject:currentVerString forKey:DCPrefsAppVersion];
	return isUpgrade;
}


- (BOOL)testFirstRun
{
	BOOL result = ![[NSUserDefaults standardUserDefaults] boolForKey:PMUsageHasRunBefore];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:PMUsageHasRunBefore];
	return result;
}
@end
