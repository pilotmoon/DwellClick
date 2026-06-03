// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "NMStartAtLogin.h"

NS_ASSUME_NONNULL_BEGIN

@interface NMStartAtLogin2024 : NSObject<NMStartAtLogin>
+ (NMStartAtLogin2024 *)sharedInstance;
- (void)refreshState;
@end

NS_ASSUME_NONNULL_END
