// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMStartAtLoginController.h"
#import "NMKit.h"
#import <ServiceManagement/ServiceManagement.h>

static NSString *const NMPrefsStartAtLogin=@"NMStartAtLogin";
static NSString *const kAppHelperLabel    = @"Label";
static NSString *const kAppHelperOnDemand = @"OnDemand";

// helper bundle id
static NSString *_helper;

@implementation NMStartAtLoginController

// based on code at https://devforums.apple.com/thread/146767
+ (BOOL)bundleIDExistsAsLoginItem:(NSString *)bundleID
{    
    NSArray *const jobDicts = (__bridge_transfer NSArray *)SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    for (NSDictionary *job in jobDicts) {            
        if ([bundleID isEqualToString:job[kAppHelperLabel]]) {
            return [job[kAppHelperOnDemand] boolValue];
        }
    }
    return NO;
}

// This isn't a singleton but rather have as many instances as you like; they all work the same.
// Do it this way for IB instantiation.
- (id)init {
    self = [super init];
    if (self) {
        if (!_helper) {
            // Creating helper app complete URL
            NSURL *const helperUrl=[[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/StartAtLoginHelper.app"];
            
            // Get bundle for helper app
            NSBundle *const helperBundle=[NSBundle bundleWithURL:helperUrl];
            
            // set helper bundle identifier
            _helper=[helperBundle bundleIdentifier];
            NMLogFine(@"Helper bundle identifier is %@", _helper);
        }
    }
    return self;
}

+ (void)setFromPrefs
{
    NMStartAtLoginController *controller=[[NMStartAtLoginController alloc] init];
    
    // set based on pref in case it was "forgotten"
    const BOOL prefsState=[[NSUserDefaults standardUserDefaults] boolForKey:NMPrefsStartAtLogin];
    NMLogFine(@"Start at login is %@; prefs state is %@", @(controller.startAtLogin), @(prefsState));
    controller.startAtLogin=prefsState;
}

- (void)setStartAtLogin:(BOOL)enabled
{
    // save the pref we are setting
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:NMPrefsStartAtLogin];
    
    if (_helper) {
        if (SMLoginItemSetEnabled((__bridge CFStringRef)_helper, enabled)) {
            NMLogInfo(@"SMLoginItemSetEnabled setting %@ to %d succeeded.", _helper, enabled);
        }
        else {
            NMLogError(@"SMLoginItemSetEnabled setting %@ to %d failed.", _helper, enabled);
        }
    }
}

- (BOOL)startAtLogin
{
    return _helper&&[NMStartAtLoginController bundleIDExistsAsLoginItem:_helper];
}

@end
