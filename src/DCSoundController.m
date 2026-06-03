// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCSoundController.h"
#import "DCConstants.h"
#import "DCCommon.h"

@implementation DCSoundController

static DCSoundController * sharedInstance = nil;

// Standard singleton factory.
+ (DCSoundController *)sharedInstance
{        
	if (sharedInstance == nil)
		sharedInstance = [[DCSoundController alloc] init];
    return sharedInstance;	
}

// Load a sound scheme.
- (void)loadSoundScheme
{	
	// Set all sounds to nil.
	for(int i=0; i<DCClickTypeMax; i++) {
		sounds[i]=nil;
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsSoundsOn]) {
		// Get choices from prefs.
		NSString *clickName = [[NSUserDefaults standardUserDefaults] stringForKey:DCPrefsSoundsClick];
		NSString *dragDropName = [[NSUserDefaults standardUserDefaults] stringForKey:DCPrefsSoundsDragDrop];
		NMLogInfo(@"loading sound scheme %@+%@", clickName, dragDropName);
		
		// Load schemes from plist.
		NSDictionary *schemes=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sounds"
																										 ofType:@"plist"]];
		// Click sounds.
		if (![clickName isEqualToString:DCSoundNoSoundName]) {
			NSArray *clickScheme=schemes[clickName];
			if (clickScheme) {
				sounds[DCClickTypeSingle]=[NSSound soundNamed:clickScheme[0]];
				sounds[DCClickTypeDouble]=[NSSound soundNamed:clickScheme[1]];
				sounds[DCClickTypeTriple]=[NSSound soundNamed:clickScheme[2]];
			}			
            sounds[DCClickTypeHoverOn]=[NSSound soundNamed:schemes[@"HoverOn"]];            
		}
		
		// Drag and drop sounds.
		if (![dragDropName isEqualToString:DCSoundNoSoundName]) {
			NSArray *dragDropScheme=schemes[dragDropName];
			if (dragDropScheme) {
				sounds[DCClickTypeDragBegin]=[NSSound soundNamed:dragDropScheme[0]];
				sounds[DCClickTypeDragEnd]=[NSSound soundNamed:dragDropScheme[1]];
			}
			else {
				sounds[DCClickTypeDragBegin]=sounds[DCClickTypeDragEnd]=sounds[DCClickTypeSingle];
			}
            sounds[DCClickTypeDragLockSound]=[NSSound soundNamed:schemes[@"LockDrag"]];
		}
        
		// Set all volume.
		CGFloat vol=[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsSoundsVolume];
		for(int i=1; i<DCClickTypeMax; i++) {
			[sounds[i] setVolume:vol];
		}
	}
}

- (id)init
{
	self = [super init];
    if (self) {
        NMObservePrefsKeysUsingBlock(@[DCPrefsSoundsOn, DCPrefsSoundsVolume, DCPrefsSoundsClick, DCPrefsSoundsDragDrop], ^{
            [self loadSoundScheme];
        });
    }
	return self;
}

// Play the appropriate sound, if any, for the given click.
- (void)playSoundForClickType:(DCClickType)type
{
	[sounds[type] play];
}

@end
