// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMCoreUtils.h"
#import "NMRegexUtils.h"
#import "NMAppUtils.h"

// Returns the file path for file |name| if saved at NSURL |base|.
NSString* NMPathWithBaseURLAndName(NSURL* base, NSString* name)
{
    NSString* filteredName=[name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [[NSURL URLWithString:filteredName relativeToURL:base] path];
}

// Returns if there is already a file |name| at dir NSURL |base|.
BOOL NMFileAlreadyExists(NSURL* base, NSString* name)
{
    NSString* path = NMPathWithBaseURLAndName(base, name);
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

// Takes a destination URL, a suggested file name, & an extension (eg .webloc).
// Returns the complete file name with extension you should use.
// The name returned will not contain /, : or ?, will not be longer than
// kMaxNameLength + length of extension, and will not be a file name that
// already exists in that directory. If necessary it will try appending a space
// and a number to the name (but before the extension) trying numbers up to and
// including kMaxIndex.
// If the function gives up it returns nil.
// (from chromium - NM)
NSString* NMUnusedLegalNameForNewFile(NSURL* saveLocation, NSString *fileName, NSString *extension)
{
    int number = 1;
    const int kMaxIndex = 20;
    const unsigned kMaxNameLength = 64; // Arbitrary.
    
    NSString* filteredName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    filteredName = [filteredName stringByReplacingOccurrencesOfString:@":" withString:@"-"];
    filteredName = [filteredName stringByReplacingOccurrencesOfString:@"?" withString:@"-"];
    
    if ([filteredName length] > kMaxNameLength)
        filteredName = [filteredName substringToIndex:kMaxNameLength];
    
    NSString* candidateName = [filteredName stringByAppendingString:extension];
    
    while (NMFileAlreadyExists(saveLocation, candidateName)) {
        if (number > kMaxIndex)
            return nil;
        else
            candidateName = [filteredName stringByAppendingFormat:@" %d%@",
                             number++, extension];
    }
    
    return candidateName;
}

NSString *NMLimitString(NSString *string, NSUInteger limit, NSString *indicator)
{
    if (!string) {
        return @"";
    }
    if (!indicator) {
        indicator=@"…";
    }    
    const NSUInteger len=[string length];
    return [NSString stringWithFormat:@"%@%@", [string substringToIndex:MIN(len, limit)], len>limit?indicator:@""];
}

NSString *NMURLEscapeString(NSString *str)
{
    // RFC 2396 reserved set
    CFStringRef reservedChars=CFSTR(";/?:@&=+$,");
    
    // see http://www.bagonca.com/blog/2009/04/08/iphone-tip-1-url-encoding-in-objective-c/
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                       (__bridge CFStringRef)str,
                                                                       NULL,
                                                                       reservedChars,
                                                                       kCFStringEncodingUTF8));
}

NSString *NMUUIDString(void)
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return CFBridgingRelease(string);
}

BOOL NMUTIConformsToPlainText(NSString *uti)
{
    return UTTypeConformsTo((__bridge CFStringRef)uti, CFSTR("public.plain-text"));
}

BOOL NMUTIConformsToFileUrl(NSString *uti)
{
    return UTTypeConformsTo((__bridge CFStringRef)uti, CFSTR("public.file-url"));
}

BOOL NMCharacterIsChineseOrJapanese(uint32_t cp)
{
    // chinese from http://stackoverflow.com/questions/1366068/whats-the-complete-range-for-chinese-characters-in-unicode
    // plus katakana and hiragana articles
    return
    (cp>=0x4E00  && cp<=0x9FCC)|| // CJK unified ideographs
    (cp>=0x3400  && cp<=0x4DB5)|| // CJKUI Ext A block
    (cp>=0x20000 && cp<=0x2A6D6)|| // CJKUI Ext B block
    (cp>=0x2A700 && cp<=0x2B734)|| // CJKUI Ext C block
    (cp>=0x2B740 && cp<=0x2B81D)|| // CJKUI Ext D block
    (cp>=0x30A0  && cp<=0x30FF)|| // Katakana
    (cp>=0x31F0  && cp<=0x32FF)|| // Enclosed CJK Letters and Months + Enclosed CJK Letters and Months
    (cp>=0xFF00  && cp<=0xFFEF)|| // Halfwidth and fullwidth forms
    (cp>=0x3040  && cp<=0x309F)|| // Hiragana
    (cp>=0x1B000 && cp<=0x1B0FF); // Kana supplement
}

// detect if the string contains any chinese or japanese characters
NSUInteger NMNumberOfCJCharacters(NSString *s)
{
    NSUInteger result=0;
    NSData *const data=[s dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
    const size_t len=[data length]/sizeof(uint32_t);
    const uint32_t *buf=(uint32_t *)[data bytes];
    const uint32_t *const end=buf+len;
    for(; buf<end; buf+=1) {
        if (NMCharacterIsChineseOrJapanese(*buf)) {
            result+=1;
        }
    }
    return result;
}

// detect if the string might contain any chinese or japanese characters
BOOL NMStringMayContainCJ(NSString *s)
{
    NSData *const data=[s dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
    const size_t len=[data length]/sizeof(uint32_t);
    const uint32_t *buf=(uint32_t *)[data bytes];
    const uint32_t *const end=buf+len;
    for(; buf<end; buf+=1) {
        if (*buf>=0x3040) {
            return YES;
        }
    }
    return NO;
}

BOOL NMStringMayContainCombiningCharacters(NSString *s)
{
    NSData *const data=[s dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
    const size_t len=[data length]/sizeof(uint32_t);
    const uint32_t *buf=(uint32_t *)[data bytes];
    const uint32_t *const end=buf+len;
    for(; buf<end; buf+=1) {
        if (*buf>=0x0300) {
            return YES;
        }
    }
    return NO;
}

BOOL NMPref(NSString *key)
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

@implementation NSDictionary (NMExtensions)

+ (NSDictionary *)dictionaryWithData:(NSData *)data
{
	// uses toll-free bridging for data into CFDataRef and CFPropertyList into NSDictionary
	CFPropertyListRef plist =  CFPropertyListCreateWithData(NULL,
                                                            (__bridge CFDataRef)data,
                                                            kCFPropertyListImmutable,
                                                            NULL, NULL);
	// we check if it is the correct type and only return it if it is
	if ([(__bridge id)plist isKindOfClass:[NSDictionary class]])
	{
		return (__bridge_transfer NSDictionary *)plist;
	}

    // otherwise, clean up ref
    CFRelease(plist);
    return nil;
}

- (NSDictionary *)dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dictionary;
{
    NSMutableDictionary *const result=[self mutableCopy];
    if (dictionary) {
        [result addEntriesFromDictionary:dictionary];
    }
    return [NSDictionary dictionaryWithDictionary:result];
}

@end


@implementation NSMutableDictionary (NMExtensions)

- (void)safeRemoveObjectForKey:(id)key {
    if (self[key]) {
        [self removeObjectForKey:key];
    }
}

- (void)safeSetObject:(id)anObject forKey:(id <NSCopying>)aKey {
    if (anObject&&aKey) {
        self[aKey] = anObject;
    }
}

@end


@implementation NSArray (NMExtensions)

- (id)safeFirstObject
{
    return [self count]>0?self[0]:nil;
}

- (id)safeObjectAtIndex:(NSUInteger)idx
{
    return [self count]>idx?self[idx]:nil;
}

- (NSArray *)mappedArrayUsingBlock:(NMMapBlock)block
{
    NSMutableArray *result=[NSMutableArray array];
    for (id obj in self) {
        [result safeAddObject:block(obj)];
    };
    return [result copy];
}

- (NSArray *)filteredArrayUsingBlock:(NMEvaluatorBlock)block
{
    NSMutableArray *result=[NSMutableArray array];
    for (id obj in self) {
        if (block(obj)) {
            [result addObject:obj];
        }
    };
    return [result copy];
}

- (NSSet *)collectSet:(NMMapBlock)block
{
    NSMutableSet *const result=[NSMutableSet set];
    for (id obj in self) {
        [result safeAddObject:block(obj)];
    };
    return [NSSet setWithSet:result];
}

@end


@implementation NSSet (NMExtensions)

- (NSSet *)filteredSetUsingBlock:(NMEvaluatorBlock)block
{
    NSMutableSet *result=[NSMutableSet set];
    for (id obj in self) {
        if (block(obj)) {
            [result addObject:obj];
        }
    };
    return [result copy];
}

@end


@implementation NSMutableArray (NMExtensions)

- (void)safeAddObject:(id)obj
{
    if (obj) {
        [self addObject:obj];
    }
}

@end

@implementation NSMutableSet (NMExtensions)

- (void)safeAddObject:(id)obj
{
    if (obj) {
        [self addObject:obj];
    }
}

@end

@implementation NSString (NMExtensions)

- (NSString *)urlDecode
{
    NSString *x=self;
    x=[x stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    x=[x stringByRemovingPercentEncoding];
    return x;
}

- (NSDictionary *)parseQuery
{
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    for (NSString *qs in [self componentsSeparatedByString:@"&"]) {
        if ([qs length]>0) {
            NSString *key=qs, *val=@"";
            NSRange range=[qs rangeOfString:@"="];
            if (range.location!=NSNotFound) {
                key=[qs substringToIndex:range.location];
                val=[qs substringFromIndex:range.location+1];
            }
            result[[key urlDecode]]=[val urlDecode];
        }
    }
    return [NSDictionary dictionaryWithDictionary:result];
}

- (NSString *)removePrefix:(NSString *)requiredPrefix
{
    NSString *result=nil;
    if ([self hasPrefix:requiredPrefix]) {
        result=[self substringFromIndex:[requiredPrefix length]];
    }
    return result;
}

- (NSString *)stringByRemovingCharactersInSet:(NSCharacterSet *)cs
{
    NSMutableString *const result=[self mutableCopy];
    for (NSUInteger i=[self length]; i>0; i-=1) {
        const unichar c=[self characterAtIndex:i-1];
        if ([cs characterIsMember:c]) {
            [result deleteCharactersInRange:NSMakeRange(i-1, 1)];
        }
    }
    return result;
}

- (NSString *)trimSpaces
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)trimSpacesAndNewlines
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSUInteger)characterCount
{
    // simple way if guaranteed no combining chars
    // see http://www.fileformat.info/info/unicode/category/Mn/list.htm for rationale
    if (!NMStringMayContainCombiningCharacters(self)) {
        return [self length];
    }
    
    __block NSUInteger result=0;
    [self enumerateSubstringsInRange:NSMakeRange(0, [self length])
                                     options:NSStringEnumerationByComposedCharacterSequences
                                  usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                      result+=1;
                                  }];
    return result;
}

- (NSUInteger)wordCount
{
    return [self wordCount:[self stringIsChinese]];
}

- (BOOL)stringIsChinese
{
#ifdef DEBUG
    NSDate *start=[NSDate date];
#endif
    BOOL result=NO;
    if (NMStringMayContainCJ(self)) {
        // needs at least 10% chinese characters
        const NSUInteger chineseCount=NMNumberOfCJCharacters(self);
        const NSUInteger threshold=[self length]*0.1;
        result=chineseCount>threshold;
        NMLogFine(@"chinese string detection took %f; chinese chars %lu, total chars %lu, threshold %lu, ischinese? %d", [[NSDate date] timeIntervalSinceDate:start], chineseCount, [self length], threshold, result);
    }
    return result;
}

- (NSUInteger)wordCount:(BOOL)chineseMode
{
#ifdef DEBUG
    NSDate *start=[NSDate date];
#endif
    __block NSUInteger result=0;

    // use different block depending on whether ther are any chinese and japanes characters to deal with
    void (^block)(NSString *) = chineseMode ?
    ^(NSString *word) {
        result+=word.length;
    }:
    ^(NSString *word) {
        result+=1;
    };
    
    for (NSString *word in [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
        if (word.length>0) {
            block(word);
        }
    }
    
    NMLogFine(@"word count took %f; words %lu, chinese mode? %d", [[NSDate date] timeIntervalSinceDate:start], result, chineseMode);
    return result;
}

- (NSUInteger)hexIntegerValue
{
    unsigned int result=0;
    NSScanner *scanner=[NSScanner scannerWithString:self];
    [scanner scanHexInt:&result];
    return (NSUInteger)result;
}

- (CGFloat)hexColorValue
{
    unsigned int result=0;
    NSScanner *scanner=[NSScanner scannerWithString:self];
    [scanner scanHexInt:&result];
    return result/(CGFloat)255.0;
}

- (NSURL *)URLValue
{
    NSString *string=[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([string length]>0) {
        NSError *error = NULL;
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink
                                                                   error:&error];
        NSRange range=NSMakeRange(0, [string length]);
        for (NSTextCheckingResult *match in [detector matchesInString:string options:NSMatchingAnchored range:range]) {
            NSRange matchRange = [match range];
            // only match whole string
            if (NSEqualRanges(matchRange, range)) {
                NSURL *matchedURL=match.URL;
                if (matchedURL) {
                    return [matchedURL absoluteURL];
                }
            }
            break;
        }
    }
    return nil;
}

// Parse RFC3339 formatted date. Supports several common variations.
// Some info at https://developer.apple.com/library/ios/qa/qa1480/_index.html
- (NSDate *)RFC3339DateValue
{
    NSDate *result=nil;

    // Create date formatter
    static NSDateFormatter *dateFormatter=nil;
    if (!dateFormatter) {
        dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    // Preprocess input
    NSString *inputString=[[self uppercaseString] stringByReplacingOccurrencesOfString:@"Z" withString:@"-0000"];
    
    if (!result) { // 1996-12-19T16:39:57-0800
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"];
        result=[dateFormatter dateFromString:inputString];
    }
    if (!result) { // 1937-01-01T12:00:27.87+0020
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ"];
        result=[dateFormatter dateFromString:inputString];
    }
    if (!result) { // 1937-01-01T12:00:27
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
        result=[dateFormatter dateFromString:inputString];
    }
    
    return result;
}

@end


@implementation NSURL (NMExtensions)

- (NSNumber *)fileSize
{
    NSNumber *fileSize=nil;
    if ([self isReachableFileOrDirectoryURL]) {
        [self getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
    }
    return fileSize;
}

- (BOOL)isReachableFileOnlyURL
{
    NSNumber *isDir=nil;
    if ([self isReachableFileOrDirectoryURL]) {
        [self getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:NULL]; 
    }
    return isDir&&![isDir boolValue];
}

- (BOOL)isReachableDirectoryOnlyURL
{
    NSNumber *isDir=nil;
    if ([self isReachableFileOrDirectoryURL]) {
        [self getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:NULL];
    }
    return isDir&&[isDir boolValue];
}

- (BOOL)isReachableFileOrDirectoryURL
{
    BOOL result=NO;
    if ([self isFileURL]) {
        result=[self checkResourceIsReachableAndReturnError:NULL];
    }
    return result;
}

- (BOOL)isTrashedFile
{
    BOOL result=NO;
    if (NMOSVersionCheckMavericksOrBelow()) {
        Boolean inTrash=false;
        const UInt8 *const utfPath=(UInt8*)[[self path] UTF8String];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        const OSStatus err=DetermineIfPathIsEnclosedByFolder(kOnAppropriateDisk, kTrashFolderType, utfPath, false, &inTrash);
#pragma clang diagnostic pop
        result=(err==noErr)&inTrash;
    }
    else {
        NSURLRelationship relationship=NSURLRelationshipOther;
        if([[NSFileManager defaultManager] getRelationship:&relationship
                                               ofDirectory:NSTrashDirectory
                                                  inDomain:0
                                               toItemAtURL:self
                                                     error:nil])
        {
          result=(relationship==NSURLRelationshipContains);
        }
    }
    return result;
}

- (NSURL *)parentURL
{
    NSURL *result=[[self filePathURL] URLByStandardizingPath];
    [result getResourceValue:&result forKey:NSURLParentDirectoryURLKey error:nil];
    return result;
}

- (NSArray *)allParentURLs
{
    NSMutableArray *result=[NSMutableArray array];
    NSURL *currentParent=[[self filePathURL] URLByStandardizingPath];
    do {
        [result addObject:currentParent];
        [currentParent getResourceValue:&currentParent forKey:NSURLParentDirectoryURLKey error:nil];
    } while(currentParent);
    return result;
}

- (void)removeFileAndParentIfEmpty
{
    if ([self isReachableFileOrDirectoryURL]) {
        [[NSFileManager defaultManager] removeItemAtURL:self error:nil];
        NSURL *const parent=[self URLByDeletingLastPathComponent];
        NSArray *const contents=[[NSFileManager defaultManager] contentsOfDirectoryAtURL:parent
                                                              includingPropertiesForKeys:@[]
                                                                                 options:0
                                                                                   error:nil];
        if ([contents count]==0) {
            [[NSFileManager defaultManager] removeItemAtURL:parent error:nil];
        }
    }
}

- (NSDictionary *)queryDictionary
{
    if ([self query]) {
        return [[self query] parseQuery];
    }
    else {
        return [NSDictionary dictionary];
    }
}

@end

@implementation NSColor (NMExtensions)

+ (NSColor *)colorWithHexString:(NSString *)hexString
{
    NSMutableArray *components=[NSMutableArray array];
    
    NSArray *compStrings=[[[hexString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"# "]] lowercaseString] nm_captureComponentsMatchedByRegex:@"^([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])?$"];
    if ([compStrings count]>3) {
        [components addObject:@([compStrings[1] hexColorValue])];
        [components addObject:@([compStrings[2] hexColorValue])];
        [components addObject:@([compStrings[3] hexColorValue])];
        if ([compStrings count]>4&&[compStrings[4] length]>0) {
            [components addObject:@([compStrings[4] hexColorValue])];
        }
        else {
            [components addObject:@(1)];
        }
    }

    if ([components count]==4) {
        return [NSColor colorWithCalibratedRed:[components[0] floatValue]
                                         green:[components[1] floatValue]
                                          blue:[components[2] floatValue]
                                         alpha:[components[3] floatValue]];
    }
    return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
}

@end