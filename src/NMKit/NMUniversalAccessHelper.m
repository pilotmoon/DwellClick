// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMUniversalAccessHelper.h"
#import "NMAppUtils.h"

static NMUniversalAccessHelper *_sharedInstance;

NSString *NMUniversalAccessStateChangedNotification=@"NMUniversalAccessStateChangedNotification";

@implementation NMUniversalAccessHelper

+ (NMUniversalAccessHelper *)sharedInstance
{
	if (!_sharedInstance) {
		_sharedInstance=[[NMUniversalAccessHelper alloc] init];
	}
	return _sharedInstance;
}

+ (BOOL)checkAxTrustedWithPrompt:(BOOL)prompt
{
    NSDictionary *const options=@{(__bridge NSString *)kAXTrustedCheckOptionPrompt: @(prompt)};
    return AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

- (id)init
{
    self=[super init];
    if (self) {
        [self refreshState];        
    }

	return self;
}

- (BOOL)isAxEnabled
{
	return [[self class] checkAxTrustedWithPrompt:NO];
}

- (void)refreshState
{
	BOOL is=[self isAxEnabled];
	if (is!=axWasEnabled) {
		[self willChangeValueForKey:@"axEnabled"];
		[self didChangeValueForKey:@"axEnabled"];
        [[NSNotificationCenter defaultCenter] postNotificationName:NMUniversalAccessStateChangedNotification object:self userInfo:@{@"axEnabled": @(is)}];
	}
	axWasEnabled=is;
}

+ (BOOL)enableUniversalAccess
{
    return [self checkAxTrustedWithPrompt:YES];
}

@end
