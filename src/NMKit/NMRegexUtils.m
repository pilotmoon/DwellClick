// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMRegexUtils.h"

NSString *const NMRegexUtilsKeyMatch=@"match";
NSString *const NMRegexUtilsKeyRange=@"range";

@implementation NSString (NMRegexUtils)

static NSRegularExpression *getRE(NSString *pattern)
{
    NSError *error=nil;
    NSRegularExpression *re=[NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    return error?nil:re;
}

- (BOOL)nm_isMatchedByRegex:(NSString *)regex
{
    return [getRE(regex) numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])]>0;
}

- (NSArray *)nm_componentsMatchedByRegex:(NSString *)regex
{
    NSMutableArray *result=[NSMutableArray array];
    NSArray *matches=[getRE(regex) matchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    for (NSTextCheckingResult *tcr in matches) {
        [result addObject:safeSubstring(self, tcr.range, @"")];
    }
    return result;
}

- (NSArray *)nm_arrayOfCaptureComponentsMatchedByRegex:(NSString *)regex
{
    NSMutableArray *result=[NSMutableArray array];
    NSArray *matches=[getRE(regex) matchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    for(NSTextCheckingResult *tcr in matches) {
        NSMutableArray *components=[NSMutableArray array];
        for(NSUInteger i=0; i<tcr.numberOfRanges; i++) {
            [components addObject:safeSubstring(self, [tcr rangeAtIndex:i], @"")];
        }
        [result addObject:components];
    }
    return result;
}

- (NSArray *)nm_captureComponentsMatchedByRegex:(NSString *)regex
{
    NSMutableArray *result=[NSMutableArray array];
    NSArray *matches=[getRE(regex) matchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    for(NSTextCheckingResult *tcr in matches) {
        for(NSUInteger i=0; i<tcr.numberOfRanges; i++) {
            [result addObject:safeSubstring(self, [tcr rangeAtIndex:i], @"")];
        }
        break; //only need the first
    }
    return result;
}

- (NSArray *)nm_componentsAndRangesMatchedByRegex:(NSString *)regex
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *matches=[getRE(regex) matchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    for(NSTextCheckingResult *tcr in matches) {
        [result addObject:@{NMRegexUtilsKeyMatch:safeSubstring(self, tcr.range, @""), NMRegexUtilsKeyRange: [NSValue valueWithRange:tcr.range]}];
    }
    return result;
}

- (BOOL)nm_isRegexValid
{
    return getRE(self)!=nil;
}

static NSString *safeSubstring(NSString *str, NSRange range, NSString *failVal)
{
    if (range.location!=NSNotFound&&(range.location+range.length<=[str length])) {
        return [str substringWithRange:range];
    }
    else {
        return failVal;
    }
}

@end
