// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

extern NSString *NMUniversalAccessStateChangedNotification;

@interface NMUniversalAccessHelper : NSObject {
	BOOL axWasEnabled;

}
@property (readonly, getter=isAxEnabled) BOOL axEnabled;

+ (NMUniversalAccessHelper *)sharedInstance;
+ (BOOL)enableUniversalAccess;
- (void)refreshState;


@end
