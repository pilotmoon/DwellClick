// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

/*
 NSUserDefaults key for an integer to set the log level.
 */
extern NSString *const kNMLogLevel;

/*
 NSUserDefaults key for an array of strings to specify files for which to turn
 on maximum logging. Matches file name part up to the first dot (if any). For example, to specify
   /Users/me/code/MyFile.m, use the string 'MyFile'.
 Speficy from console as:
   defaults write com.example.appid NMLogFiles -array MyFile MyOtherFile MyThirdFile
 */
extern NSString *const kNMLogFiles;

/*
 NSUSerDefaults key to control whether output is logged to a file on the desktop.
 */
extern NSString *const kNMLogToFile;

/*
 This function performs the logging. Although you can call this directly, I recommend
 using one of the macros below.
 */
void NMLogLog(NSString *levelName, NSInteger levelNumber, NSString *filePath, NSString *format, ...);

/*
 The current date and time as a string.
 */
NSString *NMLogDateTimeString(void);
NSString *NMLogFineDateTimeString(void);

/*
 Macros for the predefined log levels.
 */
#if defined(NMLOG_DISABLE_ALL)
#	define NMLogImportant(...)
#	define NMLogError(...)
#else
#	define NMLogImportant(fmt, ...) NMLogLog(@"INFO", 0, @__FILE__, fmt, ##__VA_ARGS__)
#	define NMLogError(fmt, ...) NMLogLog(@"ERROR", 0, @__FILE__, fmt, ##__VA_ARGS__)
#endif

#if defined(NMLOG_DISABLE_INFO)||defined(NMLOG_DISABLE_ALL)
#	define NMLogTiny(...)
#	define NMLogFine(...)
#	define NMLogInfo(...)
#	define NMLogWarning(...)
#	define NMLogTemp(...)
#else
#	define NMLogTiny(fmt, ...) NMLogLog(@"TINY", 3, @__FILE__, fmt, ##__VA_ARGS__)
#	define NMLogFine(fmt, ...) NMLogLog(@"FINE", 2, @__FILE__, fmt, ##__VA_ARGS__)
#	define NMLogInfo(fmt, ...) NMLogLog(@"INFO", 1, @__FILE__, fmt, ##__VA_ARGS__)
#	define NMLogWarning(fmt, ...) NMLogLog(@"WARNING", 1, @__FILE__, fmt, ##__VA_ARGS__)
#	define NMLogTemp(fmt, ...) NMLogLog(@"TEMP", 0, @__FILE__, fmt, ##__VA_ARGS__)
#endif



