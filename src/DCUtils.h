// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#include <Foundation/Foundation.h>
#include <ApplicationServices/ApplicationServices.h>

NSDate *DCExpireDate(NSUInteger days);

BOOL DCGetCapsLockState(void);

NSString *DCProductID(void);
BOOL DCBundleIDIsOurs(NSString *bid);
