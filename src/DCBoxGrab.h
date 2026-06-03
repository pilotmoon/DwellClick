// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <CoreFoundation/CoreFoundation.h>
#import <ApplicationServices/ApplicationServices.h>

Boolean DCBoxAtPoint(CGPoint point, uint32_t *data, CGFloat box_size);
NSData *DCBoxDataAtPoint(NSPoint point, NSUInteger pixels);
