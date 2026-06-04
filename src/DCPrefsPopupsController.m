// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCPrefsController.h"
#import "DCPrefsPopupsController.h"
#import "DCConstants.h"
#import "DCUtils.h"
#import "DCEngine.h"
#import "DCPopupWindowButtonProxy.h"
#import "DCCommon.h"
#import "NMKit/NMGeometryUtils.h"
#import <ShortcutRecorder/ShortcutRecorder.h>

@implementation DCPrefsPopupsController
@synthesize prefsController;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)fnShortcut
{
    NSString *const key=[DCPrefsController prefsKeyForShortcutIdentifier:@"FnEquiv"];
    id rep=[[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
    if (rep)
	{
		SRShortcut *shortcut=[SRShortcut shortcutWithDictionary:rep];
		if (shortcut)
		{
            NSString *modifiers=[SRSymbolicModifierFlagsTransformer.sharedTransformer transformedValue:@(shortcut.modifierFlags)];
            NSString *keyEquivalent=[SRKeyEquivalentTransformer.sharedTransformer transformedValue:shortcut];
            if (modifiers&&keyEquivalent) {
                return [modifiers stringByAppendingString:keyEquivalent.uppercaseString];
            }
            return [shortcut readableStringRepresentation:YES];
        }
    }
    return nil;
}


- (NSString *)shortcutString
{
    BOOL ignoreFn=[[NSUserDefaults standardUserDefaults] boolForKey:@"IgnoreFnKey"];
    if ([self fnShortcut]) {
        if (ignoreFn) {
            return [NSString stringWithFormat:NSLocalizedString(@"To show the popup, press %@", nil), [self fnShortcut]];
        }
        else {
            return [NSString stringWithFormat:NSLocalizedString(@"To show the popup, press %@ or fn", nil), [self fnShortcut]];
        }
    }
    else {
        if (ignoreFn) {
            return NSLocalizedString(@"To show the popup, set a keyboard shortcut", nil);
        }
        else {
            return NSLocalizedString(@"To show the popup, press fn", nil);
        }
    }
}

- (id)defaults {
    return [NSUserDefaults standardUserDefaults];
}

- (void)defaultsDidChange:(NSNotification *)notification
{
    [self willChangeValueForKey:@"shortcutString"];
    [self didChangeValueForKey:@"shortcutString"];
}


- (void)redrawPreview
{
    [previewBackgroundView removeFromSuperview];
    
	// nub top pr bottom
	BOOL under=[[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsPopupsUnderneath];
	[proxyWindow setNubPosition:under?NMNubPositionTop:NMNubPositionBottom];
	[proxyWindow setNubSize:[NMPopupWindowButton nubSize]];
	
	// buttons
	NSMutableArray *proxyButtons=[NSMutableArray array];
	NSDictionary *displayNames=nil;
	for (NSString *name in [NSArray arrayWithConfigName:@"DefaultPopupsClicks"])
	{
		NMPopupWindowButton *button=proxyButtonCache[name];
		if (!button) {
			if (!displayNames) {
				displayNames=[NSDictionary dictionaryWithConfigName:@"DisplayNames"];	
			}
			
			// create and save the button
			button=[[DCPopupWindowButtonProxy alloc] initWithFrame:NSZeroRect];
			proxyButtonCache[name] = button;

			// set title and image
			[button setTitle:displayNames[name]];
			[button setImage:[NSImage symbolForName:name]];			
		}
		[proxyButtons addObject:button];
	}
	[proxyWindow preparePopupWithButtons:proxyButtons nubLocation:NSZeroPoint];

	// view sizes
	[previewBackgroundView setFrameSize:proxyWindow.nubWindowFrame.size];
	[previewBorderView setFrameSize:proxyWindow.nubWindowFrame.size];
	
	// buttons
	for (NSView *v in [[previewBackgroundView subviews] copy])
	{
		[v removeFromSuperview];
	}
	for (NMPopupWindowButton *v in [[[proxyWindow contentView] subviews] copy])
	{
		if ([v isKindOfClass:[NMPopupWindowButton class]]) {
			[v updateSize];
			[previewBackgroundView addSubview:v];
		}
	}
	[previewBackgroundView addSubview:previewBorderView];
	
	// opacity
	[previewBackgroundView setAlphaValue:0.9];
	
	// center it
	NSSize boxSize=[previewBox frame].size;
	[previewBackgroundView setFrameOrigin:NMPointForCenteredBoxInBox([previewBackgroundView frame].size, boxSize)];
    
    [previewBox addSubview:previewBackgroundView];
}

- (id)init {
	self = [super initWithNibName:@"PrefsPopups" bundle:nil];
	if (self) {		
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultsDidChange:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
        NMObservePrefsKeysUsingBlock(@[DCPrefsPopupsUnderneath, DCPrefsPopupsSize], ^{
           	[self redrawPreview];
        });
		proxyButtonCache=[NSMutableDictionary dictionary];
		
		// proxy window
		proxyWindow=[[NMPopupWindow alloc] init];
		proxyWindow.avoidEdgeOverlap=NO;
        proxyWindow.fake=YES;
		
		// views
        previewBackgroundView=[[NMPopupWindowBackgroundView alloc] initWithFrame:NSZeroRect];
        previewBackgroundView.ownerWindow=proxyWindow;
        previewBorderView=[[NMPopupWindowBorderView alloc] initWithFrame:NSZeroRect];
        previewBorderView.ownerWindow=proxyWindow;
	}
    return self;
}

- (void)awakeFromNib
{
	[previewBox addSubview:previewBackgroundView];
	[self redrawPreview];
}

- (IBAction)getHelp:(id)sender
{
	[prefsController getHelp:sender];
}


@end
