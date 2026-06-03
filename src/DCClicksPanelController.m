// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCClicksPanelController.h"
#import "DCNewClicksPanel.h"
#import "DCNewClicksPanelButton.h"
#import "DCConstants.h"
#import "DCEngine.h"
#import "NMKit/NMKit.h"

static CGFloat _fullAlpha;
static NSTimeInterval _fadeTime;

static NSString *const kClicksPanelHasBeenShown=@"ClicksPanelHasBeenShown";
static NSString *const kClicksPanelTrackingButton=@"button";

@implementation DCClicksPanelController

+ (void)initialize
{
    if (self==[DCClicksPanelController class]) {
        _fadeTime=[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsClicksPanelFadeInterval];
        _fullAlpha=[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsClicksPanelOpacity];
    }
}

- (void)updateSizes
{
    const CGFloat sizeSetting=[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsClicksPanelSize];
	
	if (sizeSetting>0.9) {
        buttonSize=NSMakeSize(78, 52);
        gap=21;
        end=28;
	}
	else if (sizeSetting>0.6) {
        buttonSize=NSMakeSize(60, 40);
        gap=15;
        end=24;
	}
	else if (sizeSetting>0.3) {
        buttonSize=NSMakeSize(48, 32);
        gap=12; 
        end=20;
	}
    else {
        buttonSize=NSMakeSize(36, 24);
        gap=9; 
        end=18;        
	}
}

- (void)setPanelButton:(NSButton *)button mouseInside:(BOOL)mouseInside
{
    if (![button isKindOfClass:[DCNewClicksPanelButton class]]) {
        return;
    }
    DCNewClicksPanelButton *panelButton=(DCNewClicksPanelButton *)button;
    if (panelButton.mouseInsideButton!=mouseInside) {
        panelButton.mouseInsideButton=mouseInside;
        [panelButton setNeedsDisplay:YES];
    }
}

- (void)clearButtonHoverStates
{
    for (NSButton *button in [_buttonCache allValues]) {
        [self setPanelButton:button mouseInside:NO];
    }
}

- (void)syncButtonHoverStates
{
    if (![[self window] isVisible]||hide) {
        [self clearButtonHoverStates];
        return;
    }
    for (NSButton *button in [_buttonCache allValues]) {
        BOOL mouseInside=([button superview]!=nil&&[button isEnabled]&&NMMouseInView(button));
        [self setPanelButton:button mouseInside:mouseInside];
    }
}

// (Re)draw panel with the buttons specified.
- (void)configurePanelWithControls:(NSArray *)controls
{
    const NSInteger corner=[NMPopupWindow classicStyle]?1:0;
    
	const BOOL isHorizontal=([[NSUserDefaults standardUserDefaults] integerForKey:DCPrefsClicksPanelStyle]==DCPanelStyleHorizontal);
	const NSRect contentRect=[NSWindow contentRectForFrameRect:[[self window] frame]
									 styleMask:[[self window] styleMask]];
	// Remove all existing views from panel.
	for(NSView *view in [[[[self window] contentView] subviews] copy])
	{
        if ([view isKindOfClass:[NSButton class]]) {
            [self setPanelButton:(NSButton *)view mouseInside:NO];
        }
		[view removeFromSuperview];
        for (NSTrackingArea *ta in [view trackingAreas]) {
            [view removeTrackingArea:ta];
        }
	}
	
	// First pass to resize buttons and add up heights.
	CGFloat contentLength=2*end;
	for(NSView *b in controls) {
        if ([b isKindOfClass:[NSButton class]]) {
            [b setFrameSize:buttonSize];
            [b addTrackingArea:[[NSTrackingArea alloc] initWithRect:[b bounds]
                                                            options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                              owner:self
                                                           userInfo:@{kClicksPanelTrackingButton:b}]];
            contentLength+=isHorizontal?buttonSize.width:buttonSize.height;
        }
        else {
            contentLength+=gap;
        }
    }
    
    // set frame
    NSRect originalFrame=[[self window] frame];
    BOOL firstLayout=originalFrame.size.height<0.1;
    
    NMBasicBlock setf=^{
        NSRect newContent=contentRect;
        newContent.size.width=isHorizontal?contentLength:buttonSize.width+(corner*2);
        newContent.size.height=isHorizontal?buttonSize.height+(corner*2):contentLength;
        NSRect newRect=[[self window] frameRectForContentRect:newContent];
        if (!firstLayout) {
            newRect.origin.y=originalFrame.origin.y+(originalFrame.size.height-newRect.size.height);
        }
        fullLength=contentLength;    
        [[self window] setFrame:newRect display:NO];
    };

    [[self window] orderOut:self];
    setf();
    
 	// Draw controls.
	CGFloat place=isHorizontal?end:contentLength-end;
	for(NSButton *b in controls)
	{
		if ([b isEqual:[NSNull null]]) {
			place=isHorizontal?(place+gap):(place-gap);
		}
		else {
			if(isHorizontal)
			{
				[b setFrameOrigin:NSMakePoint(place,corner)];
				place+=[b frame].size.width;
			}
			else
			{
				place-=[b frame].size.height;				
				[b setFrameOrigin:NSMakePoint(corner,place)];
			}
			[[[self window] contentView] addSubview:b];
		}
	}	
    
    if ([[self window] respondsToSelector:@selector(resetBorder)]) {
        [(DCNewClicksPanel *)[self window] resetBorder];
    }
    [[self window] orderFront:self];
    [self syncButtonHoverStates];
}

- (NSButton *)generateButtonForName:(NSString *)name
{
	NSButton *button=nil;
	DCUniqueSelection *action = (_engine.clictionary)[name];
	if(action) {
        button=[((DCNewClicksPanel *)[self window]) buttonWithFrame:NSMakeRect(0, 0, buttonSize.width, buttonSize.height)];
        NSString *altName=[NSDictionary dictionaryWithConfigName:@"DisplayIcons"][name];
        [button setImage:[NSImage imageNamed:altName?altName:name]];
        [button setTarget:self];
        [button setAction:@selector(panelButtonPressed:)];
        if (![name isEqualToString:@"On-Off"]) {
            [button bind:@"enabled" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.AutoClickOn" options:nil];
        }

		[action bindToButton:button];
		[_buttonCache setValue:button forKey:name];				
	} 
	return button;
}

- (void)fadePanelIn
{
    if (hide) {
        NMLogTiny(@"Fading panel in");        
        [[[self window] animator] setAlphaValue:_fullAlpha];
    }
    hide=NO;
}

- (void)fadePanelOut
{
    if (!hide) {
        NMLogTiny(@"Fading panel out");        
        [[[self window] animator] setAlphaValue:0];    
    }
    hide=YES;    
}

// set up auto hide observer
- (void)handleMouseMovement:(BOOL)forceShow
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsClicksPanelShown]) {
        const CGFloat FADE_DISTANCE=buttonSize.width;

        if (forceShow ||
            ![[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsClicksPanelAutoHide] ||
            NSPointInRect([NSEvent mouseLocation], NSInsetRect([self window].frame, -FADE_DISTANCE, -FADE_DISTANCE))) {
            [self fadePanelIn];
            [fadeTimer invalidate];
            fadeTimer=nil;
        }
        else {
            if (!hide&&![fadeTimer isValid]) {
                NMLogFine(@"Setting fade timer for %f seconds.", _fadeTime);
                fadeTimer=[NSTimer scheduledTimerWithTimeInterval:_fadeTime block:^{
                    [self fadePanelOut];                                                        
                } repeats:NO];
            }
        }
    }
    [self syncButtonHoverStates];
}

- (id)init
{
    self = [super initWithWindow:[[DCNewClicksPanel alloc] init]];
    
	[[self window] setTitle:@""];
	[[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	
	[self window].delegate=self;

	// Set up window position saving.
	[self setShouldCascadeWindows:NO];
	
	// Set ivars
	_engine=[DCEngine sharedInstance];
	_buttonCache=[NSMutableDictionary dictionary];
    

    [NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *event) {
        [self handleMouseMovement:NO];
    }];

    [NSEvent addLocalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *event) {
        [self handleMouseMovement:NO];
        return event;
    }];

    // prevent glitch when click on after hover on
    __block BOOL suppress=NO;
    NMObservePrefsKeyUsingBlock(DCPrefsAutoClickOn, ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsAutoClickOn]) {            
            if(NMMouseInView(_onOffButton)) {
                NMRunAsyncOnMainThread(^{
                    if ([lastClickTime timeIntervalSinceNow]<-0.05) {
                        suppress=YES;
                        NMRunAsyncOnMainThreadWithDelay(0.3, ^{
                            suppress=NO;
                        });
                    }
                });
            }
        }
    });
    [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^(NSEvent *event) {
        return suppress?nil:event;
    }];
    
    [[self window] setOpaque:NO];
    [[self window] setAlphaValue:0];
    [self fadePanelOut];
    
    NMObservePrefsKeysUsingBlock(@[DCPrefsClicksPanelShown,
                                  DCPrefsClicksPanelStyle,
                                  DCPrefsClicksPanelClicks,
                                  DCPrefsClicksPanelSize], ^{
        if([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsClicksPanelShown])
        {        
            [self updateSizes];
             
            // Build array of buttons for panel.
            NSMutableArray *controls=[NSMutableArray array];
            
            // First build button names list.
            NSMutableArray *buttonNames = [NSMutableArray arrayWithObject:@"On-Off"];        
            NSArray *clicks=[[NSUserDefaults standardUserDefaults] arrayForKey:DCPrefsClicksPanelClicks];

            BOOL gap1=NO, gap2=NO;
            NSSet *group1=[NSSet setWithObjects:@"Click", @"Double-Click", @"Triple-Click", @"Drag", nil];
            NSSet *group2=[NSSet setWithObjects:@"ToggleCommand", @"ToggleControl", @"ToggleOption", @"ToggleShift", nil];                           
            
            for (NSString *name in clicks) {
                if (!gap1&&[group1 containsObject:name]) {
                    [buttonNames addObject:[NSNull null]];
                    gap1=YES;
                }
                if (!gap2&&[group2 containsObject:name]) {
                    [buttonNames addObject:[NSNull null]];
                    gap2=YES;
                }
                if (gap1||gap2) {
                    if ([name isEqual:@"Lock"]) {
                        [buttonNames addObject:[NSNull null]];
                    }
                    [buttonNames addObject:name];
                }
            }
            
            // Generate actual controls.
            for(NSString *name in buttonNames)
            {
                if ([name isEqual:[NSNull null]]) 
                {
                    [controls addObject:[NSNull null]];
                }
                else
                {
                    // Get existing button or create new one.
                    NSButton *b=_buttonCache[name];
                    if (!b) {		
                        b=[self generateButtonForName:name];
                    }
                    if(b) {
                        [controls addObject:b];
                    }
                }
            }
            
            _onOffButton=_buttonCache[@"On-Off"];
            _lockButton=_buttonCache[@"Lock"];
            
            [self configurePanelWithControls:controls];
            
            if (![[NSUserDefaults standardUserDefaults] boolForKey:kClicksPanelHasBeenShown])
            {
                NSRect screenFrame=[[NSScreen screens][0] visibleFrame];
                [[self window] setFrameOrigin:NSMakePoint(20, NMRectForCenteredBoxInBox([[self window] frame].size, screenFrame.size).origin.y)];
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kClicksPanelHasBeenShown];
            [[self window] setFrameAutosaveName:@"ClicksPanel"];                        
            [self showWindow:self];
        }
        else
        {
            [[self window] close];
        }
    });
    

    NMObservePrefsKeyUsingBlock(DCPrefsClicksPanelAutoHide, ^{
        if([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsClicksPanelShown])
        {
            [self showWindow:self];
        }
    });
    
    __block BOOL firstTime=YES;
    NMObservePrefsKeyUsingBlock(DCPrefsAutoClickOn, ^{
        NMRunAsyncOnMainThread(^{
            const BOOL isHorizontal=([[NSUserDefaults standardUserDefaults] integerForKey:DCPrefsClicksPanelStyle]==DCPanelStyleHorizontal);
            const NSRect originalFrame=[[self window] frame];
            NSRect newFrame=originalFrame;

            if ([[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsAutoClickOn]) {
                if (isHorizontal) {
                    newFrame.size.width=fullLength;
                }
                else {
                    newFrame.size.height=fullLength;
                    newFrame.origin.y=originalFrame.origin.y+(originalFrame.size.height-newFrame.size.height);                    
                }
            }
            else {
                if (isHorizontal) {
                    newFrame.size.width=buttonSize.width+2*end;
                }
                else {
                    newFrame.size.height=buttonSize.height+2*end;
                    newFrame.origin.y=originalFrame.origin.y+(originalFrame.size.height-newFrame.size.height);
                }            
            }
            [[self window] setFrame:newFrame display:YES animate:!firstTime];
            firstTime=NO;
        });
    });
    
    return self;
}

- (IBAction)panelButtonPressed:(id)sender
{
    if (![_onOffButton isEqual:sender] ) {
        [_engine turnDwellClickOnFromPanel];  
    }
    else {
        lastClickTime=[NSDate date];
    }
}

- (void)showWindow:(id)sender
{
	[super showWindow:sender];
    [self handleMouseMovement:YES];
    [self handleMouseMovement:NO];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self clearButtonHoverStates];
    [self fadePanelOut];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    NSButton *button=[[theEvent trackingArea] userInfo][kClicksPanelTrackingButton];
    [self setPanelButton:button mouseInside:YES];
	if (!_engine.mouseInPanel) {
        _engine.mouseInPanel=YES;
    }
    if ([[_onOffButton trackingAreas] containsObject:[theEvent trackingArea]] ) {
        if (!_engine.mouseInActivationArea) {
            _engine.mouseInActivationArea=YES;
        }
    }
    [[self window] display];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    NSButton *button=[[theEvent trackingArea] userInfo][kClicksPanelTrackingButton];
    [self setPanelButton:button mouseInside:NO];
	if (_engine.mouseInPanel) {
        _engine.mouseInPanel=NO;
    }
    if ([[_onOffButton trackingAreas] containsObject:[theEvent trackingArea]] ) {
        if (_engine.mouseInActivationArea) {
            _engine.mouseInActivationArea=NO;
        }
    }   
    [[self window] display];
}

@end
