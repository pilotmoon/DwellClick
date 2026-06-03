// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCPrefsPanelController.h"
#import "DCPrefsController.h"
#import "DCConstants.h"
#import "NMKit/NMKit.h"

@implementation DCPrefsPanelController
@synthesize buttonBox;
@synthesize prefsController;

- (NSImage *)templateImageForButtonName:(NSString *)name
{
    NSString *altImage=[NSDictionary dictionaryWithConfigName:@"DisplayIcons"][name];
    NSImage *image=[[NSImage imageNamed:altImage?altImage:name] copy];
    image.template=YES;
    return image;
}

- (id)init {
	self = [super initWithNibName:@"PrefsPanel" bundle:nil];
	if (self) {		
        buttonOrder=@[@"Click",
                     @"Double-Click",
                     @"Drag",
                     @"ToggleControl",
                     @"ToggleOption",
                     @"ToggleShift",
                     @"ToggleCommand",
                     @"Lock"];
	}
    return self;
}

- (void)updatePanelClicks
{
    NSMutableArray *result=[NSMutableArray array];
    for (NSButton *btn in checkBoxArray) {
        if ([btn state]==NSOnState) {
            [result addObject:buttonOrder[[btn tag]]];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:result forKey:DCPrefsClicksPanelClicks];
    BOOL enableRepeat=!([result count]==0 || ([result count]==1 && [result containsObject:@"Lock"]));
    [(NSButton *)checkBoxArray[[checkBoxArray count]-1] setEnabled:enableRepeat];
    [(NSImageView *)imageArray[[imageArray count]-1] setEnabled:enableRepeat];
}

- (IBAction)checkBoxClicked:(id)sender
{
    [self updatePanelClicks];
}

- (void)awakeFromNib
{
    // get array of check boxes and images
    checkBoxArray=[NSMutableArray array];
    imageArray=[NSMutableArray array];
   
    for (NSView *w in self.buttonBox.subviews) {
        for (NSView *v in [w subviews]) {
            NMLogInfo(@"%@", v);
            if ([v isKindOfClass:[NSButton class]]) {
                [(NSMutableArray *)checkBoxArray addObject:v];
            }
            else if ([v isKindOfClass:[NSImageView class]]) {
                [(NSMutableArray *)imageArray addObject:v];
            }
        }
    }
     
    // sort them
    NSComparator comparator=^NSComparisonResult(NSView *v1, NSView *v2) {
        if ([v1 tag] > [v2 tag]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        if ([v1 tag] < [v2 tag]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    };
    [(NSMutableArray *)checkBoxArray sortUsingComparator:comparator];
    [(NSMutableArray *)imageArray sortUsingComparator:comparator];
    
    for (NSImageView *iv in imageArray) {
        NSString *name=buttonOrder[[iv tag]];
        [iv setImage:[self templateImageForButtonName:name]];
        iv.contentTintColor=[NSColor labelColor];
        NMObserveKeyUsingBlock(iv, @"enabled", ^{
            iv.alphaValue=[iv isEnabled]?1.0:0.4;
        });
        [iv bind:@"enabled" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.ClicksPanelShown" options:nil];
    }

    for (NSButton *b in checkBoxArray) {
        [b setTarget:self];
        [b setAction:@selector(checkBoxClicked:)];
        [b bind:@"enabled" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.ClicksPanelShown" options:nil];
        NSString *name=buttonOrder[[b tag]];
        [b setState:[[[NSUserDefaults standardUserDefaults] arrayForKey:DCPrefsClicksPanelClicks] containsObject:name]];
    }
    [self updatePanelClicks];
}

- (id)defaults
{
    return [NSUserDefaultsController sharedUserDefaultsController]; 
}

- (IBAction)getHelp:(id)sender
{
	[prefsController getHelp:sender];
}

@end
