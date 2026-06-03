// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMAppMonitor.h"

NSString *NMAppMonitorAppStartedRunning=@"NMAppMonitorAppStartedRunning";
NSString *NMAppMonitorAppFinishedLaunching=@"NMAppMonitorAppFinishedLaunching";
NSString *NMAppMonitorAppStoppedRunning=@"NMAppMonitorAppStoppedRunning";

@implementation NMAppMonitor
@synthesize knownApps=_knownApps;

static NMAppMonitor *_sharedInstance=nil;

+ (NMAppMonitor *)sharedInstance
{
	if (!_sharedInstance) {
		_sharedInstance=[[NMAppMonitor alloc] init];
	}
	return _sharedInstance;
}

- (id)init
{
	self=[super init];
	if (self) {
		_knownApps=[NSMutableSet set];
		[[NSWorkspace sharedWorkspace] addObserver:self forKeyPath:@"runningApplications" options:NSKeyValueObservingOptionInitial context:0];
	}
	return self;
}

- (void)dealloc
{
    [[NSWorkspace sharedWorkspace] removeObserver:self forKeyPath:@"runningApplications"];
}

- (void)updateWithApps:(NSSet *)apps
{	
	// find dead apps
	for(NSRunningApplication *app in self.knownApps)
	{
		if (![apps containsObject:app]) {
            [app removeObserver:self forKeyPath:@"isFinishedLaunching"];
			[[NSNotificationCenter defaultCenter] postNotificationName:NMAppMonitorAppStoppedRunning object:app];
		}
	}
	
	// find new apps
	for(NSRunningApplication *app in apps)
	{
		if (![self.knownApps containsObject:app]) {
			[app addObserver:self forKeyPath:@"isFinishedLaunching" options:NSKeyValueObservingOptionInitial context:0];
			[[NSNotificationCenter defaultCenter] postNotificationName:NMAppMonitorAppStartedRunning object:app];
		}
	}
	
	[self.knownApps setSet:apps];
}

- (void)updateWithApp:(NSRunningApplication *)app
{
	if (app.finishedLaunching) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMAppMonitorAppFinishedLaunching object:app];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([object isEqual:[NSWorkspace sharedWorkspace]] && [@"runningApplications" isEqualToString:keyPath]) {
		[self updateWithApps:[NSSet setWithArray:[object runningApplications]]];
	}
	else if([object isKindOfClass:[NSRunningApplication class]] && [@"isFinishedLaunching" isEqualToString:keyPath]) {
		[self updateWithApp:object];
	}
}

- (void)forgetAndResend
{
    for (NSRunningApplication *app in self.knownApps) {
        [app removeObserver:self forKeyPath:@"isFinishedLaunching"];
    }
    [self.knownApps removeAllObjects];
    [self updateWithApps:[NSSet setWithArray:[[NSWorkspace sharedWorkspace] runningApplications]]];
}

@end