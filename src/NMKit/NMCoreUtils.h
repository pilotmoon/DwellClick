// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "NMBlockUtils.h"

/* Static Methods */
NSString* NMPathWithBaseURLAndName(NSURL* base, NSString* name);
BOOL NMFileAlreadyExists(NSURL* base, NSString* name);
NSString* NMUnusedLegalNameForNewFile(NSURL* saveLocation, NSString *fileName, NSString *extension);
NSString *NMLimitString(NSString *string, NSUInteger limit, NSString *indicator);
NSString *NMURLEscapeString(NSString *str);
NSString *NMUUIDString(void);
BOOL NMUTIConformsToPlainText(NSString *uti);
BOOL NMUTIConformsToFileUrl(NSString *uti);
BOOL NMCharacterIsChineseOrJapanese(uint32_t cp);
BOOL NMPref(NSString *key);

/* Categories */
@interface NSDictionary (NMExtensions)
+ (NSDictionary *)dictionaryWithData:(NSData *)data;
- (NSDictionary *)dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dictionary;
@end

@interface NSMutableDictionary (NMExtensions)
- (void)safeSetObject:(id)anObject forKey:(id <NSCopying>)aKey;
- (void)safeRemoveObjectForKey:(id)key;
@end

@interface NSArray (NMExtensions)
- (id)safeFirstObject;
- (id)safeObjectAtIndex:(NSUInteger)idx;
- (NSArray *)mappedArrayUsingBlock:(NMMapBlock)block;
- (NSArray *)filteredArrayUsingBlock:(NMEvaluatorBlock)block;
- (NSSet *)collectSet:(NMMapBlock)block;
@end

@interface NSSet (NMExtensions)
- (NSSet *)filteredSetUsingBlock:(NMEvaluatorBlock)block;
@end

@interface NSMutableArray (NMExtensions)
- (void)safeAddObject:(id)obj;
@end

@interface NSMutableSet (NMExtensions)
- (void)safeAddObject:(id)obj;
@end

@interface NSString (NMExtensions)
-(NSDictionary *)parseQuery;
-(NSString *)removePrefix:(NSString *)requiredPrefix;
-(NSString *)stringByRemovingCharactersInSet:(NSCharacterSet *)cs;
-(NSString *)trimSpaces;
-(NSString *)trimSpacesAndNewlines;
-(NSUInteger)characterCount;
-(NSUInteger)wordCount;
- (BOOL)stringIsChinese;
-(NSUInteger)wordCount:(BOOL)chineseMode;
- (NSUInteger)hexIntegerValue;
- (CGFloat)hexColorValue;
- (NSURL *)URLValue;
- (NSDate *)RFC3339DateValue;
@end

@interface NSURL (NMExtensions)
- (NSNumber *)fileSize;
- (BOOL)isReachableFileOnlyURL;
- (BOOL)isReachableDirectoryOnlyURL;
- (BOOL)isReachableFileOrDirectoryURL;
- (BOOL)isTrashedFile;
- (NSURL *)parentURL;
- (NSArray *)allParentURLs;
- (void)removeFileAndParentIfEmpty;
- (NSDictionary *)queryDictionary;
@end

@interface NSColor (NMExtensions)
+ (NSColor *)colorWithHexString:(NSString *)rgbaString;
@end