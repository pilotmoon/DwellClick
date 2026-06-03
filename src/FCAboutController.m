// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "FCAboutController.h"
#import "DCEngine.h"
#import "DCAboutWindow.h"
#import "DCLinks.h"
#import "DCConstants.h"

@implementation FCAboutController


- (id)init {
	nib=[[NSNib alloc] initWithNibNamed:@"About" bundle:nil];
    NSArray *tloTemp=nil;
    if (![nib instantiateWithOwner:self topLevelObjects:&tloTemp]) return nil;
    topLevelObjects=tloTemp;

	self.window=[[DCAboutWindow alloc] initWithContentRect:[contents frame]
											styleMask:NSBorderlessWindowMask
											  backing:NSBackingStoreBuffered
												defer:NO];
	
	[[self window] setHasShadow:NO];
	[[self window] setContentView:contents];
	[[self window] setContentSize:[contents frame].size];
	[[self window] center];
	[[self window] setLevel:NSFloatingWindowLevel];
	[[self window] setOpaque:NO];
	[[self window] setBackgroundColor:[NSColor clearColor]];
	[[self window] setMovableByWindowBackground:YES];
	return self;
}

- (DCEngine *)engine
{
	return [DCEngine sharedInstance];
}

- (void)showWindow:(id)sender
{
	[[self window] center];
	[NSApp activateIgnoringOtherApps:YES];
	[[self window] makeKeyAndOrderFront:self];
}

- (IBAction)closeAboutWindow:(id)sender
{
	[[self window] close];
}

- (NSString *)copyrightStatement
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
}

- (NSString *)versionStatement
{
	NSString *base=@"%@";
	return [NSString stringWithFormat:base, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

- (NSString *)webLink
{
	return @"pilotmoon.com/dwellclick";
}

@end
