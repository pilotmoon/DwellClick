// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMAppSupportDir.h"


@implementation NMAppSupportDir

// Return guaranteed path to our app support directory. Nil if cant make one.
+ (NSString *)specialDir:(NSSearchPathDirectory)directory withName:(NSString *)name
{
	NSString *result = nil; 
	NSArray *paths = NSSearchPathForDirectoriesInDomains(directory,
														 NSUserDomainMask, YES);
	if ([paths count] > 0) {
		NSString *asd = [paths[0] stringByAppendingPathComponent:name];
		
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDir = NO;
        
		if (![fm fileExistsAtPath:asd isDirectory:&isDir]) {
			if ([fm createDirectoryAtPath:asd
			  withIntermediateDirectories:YES
							   attributes:nil
									error:NULL]) {
				result = asd;
			}
		}
		else if (isDir) {
			result = asd;
		}
	}
	return result;
}


// Return guaranteed path to our app support directory. Nil if cant make one.
+ (NSString *)appSupportDirWithName:(NSString *)name
{
	return [self specialDir:NSApplicationSupportDirectory withName:name];
}

// Copy given file or directory to app support directory. Remove old file first if present.
// Return destination path, or nil on failure.  Give the file the specified fileName.
// Remove old file first if present. 
+ (NSString *)copyFile:(NSString *)path toAppSupportDir:(NSString *)name fileName:(NSString *)fileName;
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	NSString *dest = [[self appSupportDirWithName:name] stringByAppendingPathComponent:fileName];

	// Must have a destination and source
	if (!dest || !path)
		return nil;	
	
	// Source and dest must be different
	if ([dest isEqualToString:path])
		return nil;
	
	// Source must exist
	if (![fm fileExistsAtPath:path isDirectory:&isDir])
		return nil;
	
	// Dest may exist
	if ([fm fileExistsAtPath:dest isDirectory:&isDir])
	{
		// Remove old file if it's there
		if (![fm removeItemAtPath:dest error:NULL])
			return nil;
	}
	
	// Copy in the new file
	if (![fm copyItemAtPath:path toPath:dest error:NULL])
		return nil;
	
	return dest;
}

// Copy given file to app support directory. Use original name.
// Return destination path, or nil on failure.
+ (NSString *)copyFile:(NSString *)path toApplicationSupportDirectoryWithName:(NSString *)name;
{
	return [NMAppSupportDir copyFile:path toAppSupportDir:name
							fileName:[path lastPathComponent]];
}

+ (NSURL *)tempDirForAppSupportDir:(NSString *)name
{
    NSString *cachesDir=[NMAppSupportDir appSupportDirWithName:name];
    NSURL *cachesUrl=[NSURL fileURLWithPath:cachesDir isDirectory:YES];
    NSError *error=nil;
    return [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
                                                  inDomain:NSUserDomainMask
                                         appropriateForURL:cachesUrl
                                                    create:YES
                                                     error:&error];
}


@end
