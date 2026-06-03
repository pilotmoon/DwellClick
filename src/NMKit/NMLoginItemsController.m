// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMLoginItemsController.h"

// Login items change callback.
static void loginItemsChanged(LSSharedFileListRef listRef, void *context)
{
    NMLoginItemsController *controller = (__bridge NMLoginItemsController *)context;
	
    // Emit change notification. We can't do will/did
    // around the change but this will have to do.
    [controller willChangeValueForKey:@"startAtLogin"];
    [controller didChangeValueForKey:@"startAtLogin"];
}

// Class to encapsulate "start at login" checkbox functionality.
// Note this code requires garbage collection on.
@implementation NMLoginItemsController

+ (NMLoginItemsController *)sharedInstance
{        
	static NMLoginItemsController * sharedInstance = nil;
	
	if (sharedInstance == nil)
		sharedInstance = [[NMLoginItemsController alloc] init];
    return sharedInstance;	
}


// Get reference to login items list and add observer for changes.
- (id)init
{
	if(!(self = [super init])) return nil;
	loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	NSAssert(loginItems, nil);
	if (loginItems) {
		// Add an observer so we can update the UI if changed externally.
		LSSharedFileListAddObserver(loginItems,
									CFRunLoopGetMain(),
									kCFRunLoopCommonModes,
									loginItemsChanged,
									(__bridge void *)(self));
	}
	
	// Add cleanup routine for application termination.
	[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(cleanup)
												 name:NSApplicationWillTerminateNotification
											   object:nil];
	return self;
}

- (void)dealloc
{
    if (loginItems) {
        CFRelease(loginItems);
    }
}
 
// Remove login items list observer.
- (void)cleanup
{
	if (loginItems) {
		LSSharedFileListRemoveObserver(loginItems,
									   CFRunLoopGetMain(),
									   kCFRunLoopCommonModes,
									   loginItemsChanged,
									   (__bridge void *)(self));
	}
}

// Check if app is in login items.
- (BOOL)startAtLoginWithURL:(NSURL *)itemURL;
{
	Boolean foundIt=false;
	if (loginItems) {
		UInt32 seed = 0U;
        CFArrayRef arrayRef=LSSharedFileListCopySnapshot(loginItems, &seed);
		NSArray *currentLoginItems = (__bridge NSArray*)arrayRef;
        CFRelease(arrayRef);
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
			
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				foundIt = CFEqual(URL, (__bridge CFURLRef)itemURL);
				CFRelease(URL);
				
				if (foundIt)
					break;
			}
		}
	}
	return (BOOL)foundIt;
}

// Add/remove app to/from login items.
- (void)setStartAtLogin:(BOOL)enabled withURL:(NSURL *)itemURL;
{
	if (loginItems) {
		[self willChangeValueForKey:@"startAtLogin"];
		LSSharedFileListItemRef existingItem = NULL;

		UInt32 seed = 0U;
        CFArrayRef arrayRef=LSSharedFileListCopySnapshot(loginItems, &seed);
		NSArray *currentLoginItems = (__bridge NSArray*)arrayRef;
        CFRelease(arrayRef);
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
			
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				Boolean foundIt = CFEqual(URL, (__bridge CFURLRef)itemURL);
				CFRelease(URL);
				
				if (foundIt) {
					existingItem = item;
					break;
				}
			}
		}
		
		if (enabled && (existingItem == NULL)) {
			LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
										  NULL, NULL, (__bridge CFURLRef)itemURL, NULL, NULL);
		
		} else if (!enabled && (existingItem != NULL))
			LSSharedFileListItemRemove(loginItems, existingItem);
		[self didChangeValueForKey:@"startAtLogin"];
	}
}

- (BOOL)startAtLogin
{
	return [self startAtLoginWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}
- (void)setStartAtLogin:(BOOL)enabled 
{
	[self setStartAtLogin:enabled withURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}


@end
