// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

extern NSString *const NMRegexUtilsKeyMatch;
extern NSString *const NMRegexUtilsKeyRange;

@interface NSString (NMRegexUtils)

- (BOOL)nm_isMatchedByRegex:(NSString *)regex;
- (BOOL)nm_isRegexValid;
- (NSArray *)nm_arrayOfCaptureComponentsMatchedByRegex:(NSString *)regex;
- (NSArray *)nm_captureComponentsMatchedByRegex:(NSString *)regex;
- (NSArray *)nm_componentsAndRangesMatchedByRegex:(NSString *)regex;
- (NSArray *)nm_componentsMatchedByRegex:(NSString *)regex;

@end
