// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCUtils.h"
#import "NMKit/NMEventUtils.h"

NSDate *DCExpireDate(NSUInteger days)
{
	NSCalendarDate* nowDate=[NSCalendarDate dateWithNaturalLanguageString:@__DATE__ locale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
	NSCalendarDate* expireDate=[nowDate dateByAddingTimeInterval:(60*60*24*days)];
	return expireDate?expireDate:[NSDate distantPast];
}

BOOL DCGetCapsLockState(void)
{
	return (NMGetCurrentEventFlags()&kCGEventFlagMaskAlphaShift)&&1;
}

NSString *DCProductID(void)
{
	return @"com.pilotmoon.DwellClick";
}

BOOL DCBundleIDIsOurs(NSString * bid)
{
	return [bid isEqualToString:DCProductID()] || [bid hasPrefix:[DCProductID() stringByAppendingString:@"-"]];
}
