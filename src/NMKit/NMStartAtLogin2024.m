// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMStartAtLogin2024.h"
#import "NMLog.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation NMStartAtLogin2024

+ (NMStartAtLogin2024 *)sharedInstance
{
    static NMStartAtLogin2024 *sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[[self class] alloc] init];
    }
    return sharedInstance;
}

- (void)setStartAtLogin:(BOOL)enabled
{
    if (@available(macOS 13.0, *)) {
        [self willChangeValueForKey:@"startAtLogin"];
        NSError *error = nil;
        if (enabled) {
            if (SMAppService.mainAppService.status == SMAppServiceStatusEnabled) {
                [SMAppService.mainAppService unregisterAndReturnError:&error];
            }
            [SMAppService.mainAppService registerAndReturnError:&error];
        } else {
            [SMAppService.mainAppService unregisterAndReturnError:&error];
        }
        if (error) {
            NMLogError(@"Error setting startAtLogin to %@: %@", @(enabled), error);
        }
        [self didChangeValueForKey:@"startAtLogin"];
    }
}

- (void)refreshState
{
    [self willChangeValueForKey:@"startAtLogin"];
    [self didChangeValueForKey:@"startAtLogin"];
}

- (BOOL)startAtLogin
{
    if (@available(macOS 13.0, *)) {
        return SMAppService.mainAppService.status == SMAppServiceStatusEnabled;
    } else {
        return NO;
    }
}

@end
