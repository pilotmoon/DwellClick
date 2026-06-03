// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>

// Helps out with copying to user's Application Support directory
@interface NMAppSupportDir : NSObject

+ (NSString *)specialDir:(NSSearchPathDirectory)directory withName:(NSString *)name;
+ (NSString *)appSupportDirWithName:(NSString *)name;
+ (NSString *)copyFile:(NSString *)path toApplicationSupportDirectoryWithName:(NSString *)name;
+ (NSString *)copyFile:(NSString *)path toAppSupportDir:(NSString *)name
			  fileName:(NSString *)fileName;
+ (NSURL *)tempDirForAppSupportDir:(NSString *)name;
@end
