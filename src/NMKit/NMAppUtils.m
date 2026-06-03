// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <ApplicationServices/ApplicationServices.h>
#import "Foundation/Foundation.h"
#import "NMAppUtils.h"
#import <sys/sysctl.h>

NSString *NMOwnBundleID(void)
{
    return [NSRunningApplication currentApplication].bundleIdentifier;
}

NSString *NMBundleIdForPID(pid_t pid)
{
    return [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
}

pid_t NMActiveApplicationPID(void)
{
    return [[NSWorkspace sharedWorkspace] menuBarOwningApplication].processIdentifier;
}

pid_t NMFocusedApplicationPID(void)
{
    return [[NSWorkspace sharedWorkspace] frontmostApplication].processIdentifier;
}

BOOL NMOwnAppIsFocused(void)
{
    return [NMBundleIdForPID(NMFocusedApplicationPID()) isEqualToString:NMOwnBundleID()];
}

NSString *NMModelIdentifier()
{
    NSString *result=@"Unknown Mac";
    size_t len=0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len) {
        NSMutableData *data=[NSMutableData dataWithLength:len];
        sysctlbyname("hw.model", [data mutableBytes], &len, NULL, 0);
        result=[NSString stringWithUTF8String:[data bytes]];
    }
    return result;
}

NSString *NMOSVersionString(void)
{
    NSOperatingSystemVersion osver={0};
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)]) {
        // Note: Though undocumented, 10.9.5 has this. 10.9.0 does not.
        osver=[[NSProcessInfo processInfo] operatingSystemVersion];
    }
    else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        Gestalt(gestaltSystemVersionMajor, (SInt32 *)&osver.majorVersion);
        Gestalt(gestaltSystemVersionMinor, (SInt32 *)&osver.minorVersion);
        Gestalt(gestaltSystemVersionBugFix, (SInt32 *)&osver.patchVersion);
#pragma clang diagnostic pop

    }
    return [NSString stringWithFormat:@"%@.%@.%@", @(osver.majorVersion), @(osver.minorVersion), @(osver.patchVersion)];
}

NSNumber *NMAppVersionNumber(void)
{
	NSString *const verNumStr=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSInteger integer=0;
    if ([[NSScanner scannerWithString:verNumStr] scanInteger:&integer]) {
        return @(integer);
    }
    return nil;
}

NSString *NMAppVersionString(void)
{
	return [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

NSString *NMLongAppVersionString(void)
{
    return [NSString stringWithFormat:@"%@ (%@)", NMAppVersionString(), NMAppVersionNumber()];
}

BOOL NMCheckAppInstalled(NSString *bid) {
    BOOL result=NO;
    CFURLRef appURL=NULL;
    OSStatus status=LSFindApplicationForInfo(kLSUnknownCreator,
                                             (__bridge CFStringRef)bid,
                                             NULL,
                                             NULL,
                                             &appURL
                                             );
    
    if(appURL) {
        CFRelease(appURL);
        if (status==noErr) {
            result=YES;
        }
    }
    return result;
}

BOOL NMOSVersionCheckSnowLeopardOrBelow()
{
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6;
}

BOOL NMOSVersionCheckLionOrBelow()
{
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7;
}

BOOL NMOSVersionCheckMountainLionOrBelow()
{
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8;
}

BOOL NMOSVersionCheckMavericksOrBelow()
{
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9;
}

BOOL NMOSVersionCheckYosemiteOrBelow()
{
    return floor(NSAppKitVersionNumber) <= 1343; //NSAppKitVersionNumber10_10
}

@implementation NSNumber (NMPidAdditions)

+ (NSNumber *)numberWithPid:(pid_t)pid
{
	return @(pid);
}

- (pid_t)pidValue
{
	return [self intValue];
}

@end
