// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

extern NSString *NMAppMonitorAppStartedRunning;
extern NSString *NMAppMonitorAppFinishedLaunching;
extern NSString *NMAppMonitorAppStoppedRunning;

@interface NMAppMonitor : NSObject {
    NSMutableSet *_knownApps;
}
+ (NMAppMonitor *)sharedInstance;
- (void)forgetAndResend;
@property (readonly) NSMutableSet *knownApps;
@end