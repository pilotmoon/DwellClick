// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCApp.h"
#import "DCAppDelegate.h"
#import "DCEngine+Gubbins.h"
#import "NMKit/NMConfigUtils.h"

@implementation DCApplication

- (DCEngine *)engine
{
	return ((DCAppDelegate *)[self delegate]).engine;
}

- (NSNumber*)enabled {
	BOOL enabled=self.engine.dwellClickOn;
	return @(enabled);
}

- (void)setEnabled:(NSNumber*)state {
	[self engine].dwellClickOn=[state boolValue];
}

- (DCUniqueSelection*) selectedAction
{
	return self.engine.clickMachine.selectedItem;
}

- (NSArray*) actions
{
	// generate actions array first time, from clicks
	static NSArray *actions=nil;
	if(!actions) {
		actions=[self.engine.clictionary objectsForKeys:[NSArray arrayWithConfigName:@"ScriptableActions"]
										 notFoundMarker:(self.engine.clictionary)[@"No-Click"]];
	}
	return actions;
}


@end
