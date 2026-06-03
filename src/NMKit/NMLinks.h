// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

@interface NMLinks : NSObject

+ (NSString *)binaryIdentifier;
+ (NSString *)identifier;
+ (NSString *)appStoreIdentifier;
+ (NSString *)displayName;
+ (NSString *)appToken;
+ (NSURL *)makeLink:(NSString *)name;
+ (void)openLink:(NSString *)name;
+ (void)openAppStore;
+ (void)composeFeedbackEmail;

@end
