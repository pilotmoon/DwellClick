// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMConfigUtils.h"

static id _configObjectWithName(NSString *name) {
    return [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config"
                                                                                      ofType:@"plist"]][name];
}
static NSMutableArray *_configArrayWithName(NSString *name)
{
    NSMutableArray *result=[[NSMutableArray alloc] init];
    void (^add)(NSArray *)=^void(NSArray *array) {
        if ([array isKindOfClass:[NSArray class]]) {
            [result addObjectsFromArray:array];
        }
    };
    
    add(_configObjectWithName(name));
    add([[NSUserDefaults standardUserDefaults] objectForKey:name]);
    
    return result;
}

static NSMutableDictionary *_configDictionaryWithName(NSString *name)
{
    NSMutableDictionary *result=[[NSMutableDictionary alloc] init];
    void (^add)(NSDictionary *)=^void(NSDictionary *dict) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            [result addEntriesFromDictionary:dict];
        }
    };
    
    add(_configObjectWithName(name));
    add([[NSUserDefaults standardUserDefaults] objectForKey:name]);
    
    return result;
}

@implementation NSSet(NMConfigUtils)
+ (NSSet *)setFromArrayWithConfigName:(NSString *)name
{
    return [NSSet setWithArray:_configArrayWithName(name)];
}
@end

@implementation NSArray(NMConfigUtils)
+ (NSArray *)arrayWithConfigName:(NSString *)name
{
    return [_configArrayWithName(name) copy];
}
@end

@implementation NSDictionary(NMConfigUtils)
+ (NSDictionary *)dictionaryWithConfigName:(NSString *)name
{
    return [_configDictionaryWithName(name) copy];
}
@end

@implementation NSMutableSet(NMConfigUtils)
+ (NSSet *)setFromArrayWithConfigName:(NSString *)name
{
    return [NSMutableSet setWithArray:_configArrayWithName(name)];
}
@end

@implementation NSMutableArray(NMConfigUtils)
+ (NSArray *)arrayWithConfigName:(NSString *)name
{
    return _configArrayWithName(name);
}
@end

@implementation NSMutableDictionary(NMConfigUtils)
+ (NSDictionary *)dictionaryWithConfigName:(NSString *)name
{
    return _configDictionaryWithName(name);
}
@end
