// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

extern NSString *const NMBrowserHelperIdentifierCamino;
extern NSString *const NMBrowserHelperIdentifierChrome;
extern NSString *const NMBrowserHelperIdentifierChromeCanary;
extern NSString *const NMBrowserHelperIdentifierFirefox;
extern NSString *const NMBrowserHelperIdentifierFirefoxAurora;
extern NSString *const NMBrowserHelperIdentifierFirefoxNightly;
extern NSString *const NMBrowserHelperIdentifierOpera;
extern NSString *const NMBrowserHelperIdentifierOmniWeb;
extern NSString *const NMBrowserHelperIdentifierSafari;
extern NSString *const NMBrowserHelperIdentifierWhiteHatAviator;

@interface NMBrowserHelper : NSObject

+ (NSSet *)knownBrowsers;
+ (NSSet *)knownBrowsersChromeGroup;
+ (NSSet *)knownBrowsersFirefoxGroup;
+ (NSString *)defaultBrowser;
+ (NSString *)bestBrowserFromApp:(NSString *)bundleIdentifier;
+ (void)openUrl:(NSURL *)url withApp:(NSString *)bundleIdentifier;
+ (void)openUrl:(NSURL *)url fromApp:(NSString *)bundleIdentifier;
+ (BOOL)searchForText:(NSString *)searchText withApp:(NSString *)bundleIdentifier;
+ (BOOL)searchForText:(NSString *)searchText fromApp:(NSString *)bundleIdentifier;
+ (NSURL *)getFrontmostUrlForApp:(NSString *)bundleIdentifier;
+ (NSString *)getFrontmostTitleForApp:(NSString *)bundleIdentifier;

@end
