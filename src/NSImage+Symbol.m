// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NSImage+Symbol.h"
#import "NMKit/NMConfigUtils.h"

@implementation NSImage(Symbol)

+ (NSImage *)symbolForName:(NSString *)name
{
	NSDictionary *dict=[NSDictionary dictionaryWithConfigName:@"DisplayIcons"];
	NSString *symbol=dict[name];
	return [NSImage imageNamed:symbol?symbol:name];
}

@end
