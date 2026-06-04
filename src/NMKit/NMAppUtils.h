// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

/*
 Utility functions relating to applications, pids, etc.
 */

#define NM_BAD_PID ((pid_t)(-1))

NSDate *NMExpireDate(NSUInteger days);

NSString *NMOwnBundleID(void);
NSString *NMBundleIdForPID(pid_t pid);

pid_t NMActiveApplicationPID(void);
pid_t NMFocusedApplicationPID(void);
BOOL NMOwnAppIsFocused(void);

NSString *NMModelIdentifier();
NSString *NMOSVersionString(void);

NSNumber *NMAppVersionNumber(void);
NSString *NMAppVersionString(void);
NSString *NMLongAppVersionString(void);

BOOL NMCheckAppInstalled(NSString *bid);



@interface NSNumber (NMPidAdditions)
+ (NSNumber *)numberWithPid:(pid_t)pid;
- (pid_t)pidValue;
@end
