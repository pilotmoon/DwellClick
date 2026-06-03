// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

/* These will always return a valid object; empty object if no content */

@interface NSSet(NMConfigUtils)
+ (NSSet *)setFromArrayWithConfigName:(NSString *)name;
@end

@interface NSArray(NMConfigUtils)
+ (NSArray *)arrayWithConfigName:(NSString *)name;
@end

@interface NSDictionary(NMConfigUtils)
+ (NSDictionary *)dictionaryWithConfigName:(NSString *)name;
@end

@interface NSMutableSet(NMConfigUtils)
+ (NSMutableSet *)setFromArrayWithConfigName:(NSString *)name;
@end

@interface NSMutableArray(NMConfigUtils)
+ (NSMutableArray *)arrayWithConfigName:(NSString *)name;
@end

@interface NSMutableDictionary(NMConfigUtils)
+ (NSMutableDictionary *)dictionaryWithConfigName:(NSString *)name;
@end
