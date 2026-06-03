// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMPopupController.h"
#import "NMPopupWindowButton.h"
#import "NMPoint.h"
#import "NMAppUtils.h"
#import "NMGeometryUtils.h"
#import "NMMouseUtils.h"
#import <NMKit/NMKit.h>
#import "Carbon/Carbon.h"

NSString *const NMPopupWillAppearGlobalNotification=@"com.pilotmoon.common.PopupWillAppear";
NSString *const NMPopupWillAppearNotification=@"com.pilotmoon.NMKit.local.PopupWillAppear";
NSString *const NMPopupDidCancelNotification=@"com.pilotmoon.NMKit.local.PopupDidCancel";
NSString *const NMPopupBoxKey=@"mouseBox";
NSString *const NMPopupReasonKey=@"reason";
NSString *const NMPopupReasonMouseAway=@"mouseAway";
NSString *const NMPopupReasonScrollWheel=@"scrollWheel";
NSString *const NMPopupReasonActionSelected=@"actionSelected";
NSString *const NMPopupReasonMouseClick=@"mouseClick";
NSString *const NMPopupReasonKeyPress=@"keyPress";
NSString *const NMPopupReasonOther=@"other";

@interface NMPopupController ()
- (void)updatePopupStyle;
@end

@implementation NMPopupController


- (void)handleNotification:(NSNotification *)note
{
    if (![(NSString *)[note object] isEqualToString:_noteObjectString]) {
        [self cancelPopup:YES];
    }
}

+ (Class)windowClass
{
    return [NMPopupWindow class];
}

- (id)init
{
    self = [super init];
    if (self) {
        _noteObjectString=NMOwnBundleID();
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:NMPopupWillAppearGlobalNotification object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
        _popupWindow=[[[[self class] windowClass] alloc] init];
        [self.popupWindow setPopupWindowDelegate:self];
        [self.popupWindow addObserver:self forKeyPath:@"mouseInWindow" options:0 context:0];
        [self.popupWindow setDelegate:self];
        [self addObserver:self forKeyPath:@"popupUnder" options:0 context:0];
        [self addObserver:self forKeyPath:@"popupSize" options:0 context:0];
        [self addObserver:self forKeyPath:@"nubless" options:0 context:0];        
        [self updatePopupStyle];
        _cancelTimeInterval=0.5;
        _longCancelTimeInterval=5.0;
        _boxDistance=40;
        _boxNubsideDistance=15;
        _actionRunDelay=0.1;
        _tipWindow=[[NMTipWindow alloc] init];
    }
    
    return self;
}

- (void)cancelBox
{
    [self notifyAbortWithReason:NMPopupReasonMouseAway];
    [self stopBoxDetect];
    [self cancelPopup];
}

- (void)checkBoxWithPoint:(NSPoint)point
{
    if (_enableBoxDetect)
    {
        BOOL mouseInBox=NSPointInRect(point, _box);
        if (mouseInBox) {
            _mouseStartsOutside=NO;
        }
        if (!mouseInBox&&!NSPointInRect(point, _mouseBox)) {
            if(!_cancelTimer) {
                _cancelTimer=[NSTimer scheduledTimerWithTimeInterval:_mouseStartsOutside?_longCancelTimeInterval:_cancelTimeInterval
                                                              target:self
                                                            selector:@selector(cancelBox)
                                                            userInfo:nil
                                                             repeats:NO];
            }
        }
        else {
            [_cancelTimer invalidate];
            _cancelTimer=nil;
        }
    }
}

- (void)startBoxDetect
{
#define BOX_NUBSIDE_EXTRA_PIXELS (self.nubless?_boxNubsideDistance+[NMPopupWindowButton nubSize]:_boxNubsideDistance)
	_box=[_popupWindow frame];
	_box=NSInsetRect(_box,(-_boxDistance),(-_boxDistance));
	_box.size.height+=BOX_NUBSIDE_EXTRA_PIXELS;
	if(_popupWindow.nubPosition==NMNubPositionBottom) {
		_box.origin.y-=BOX_NUBSIDE_EXTRA_PIXELS;			
	}
    _mouseStartsOutside=!NSPointInRect([NSEvent mouseLocation], _box);
    if (!_mouseStartsOutside) {
        const CGFloat mbox=_boxDistance;
        NSPoint p=NSPointFromCGPoint(NMCurrentUnflippedMouseLocation());
        _mouseBox=NSMakeRect(p.x-mbox, p.y-mbox, mbox*2, mbox*2);
    }
    else {
        _mouseBox=NSZeroRect;
    }
    _enableBoxDetect=YES;

}
 
- (void)stopBoxDetect
{
    _enableBoxDetect=NO;
    [_cancelTimer invalidate];
    _cancelTimer=nil;
}

- (void)updatePopupStyle
{
	[NMPopupWindowButton updateAppearance:self.popupSize];
	CGFloat nubSize=_nubless?0:[NMPopupWindowButton nubSize];
	if ([self.popupWindow nubSize]!=nubSize) {
		[self.popupWindow setNubSize:nubSize];
	}
    BOOL under=self.popupUnder;
	[self.popupWindow setPreferredNubPosition:under?NMNubPositionTop:NMNubPositionBottom];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([object isKindOfClass:[NSButton class]]&&[@"mouseInsideButton" isEqualToString:keyPath]) // in a button
	{
		BOOL inButton=((NMPopupWindowButton *)object).mouseInsideButton;
		if (inButton)
		{
			_mouseButton=object;
		}
		else 
		{
			if(object==_mouseButton) 
			{
				_mouseButton=nil;
			}
		}
	}
	else if (object==self.popupWindow&&[@"mouseInWindow" isEqualToString:keyPath]) // in ther window area
	{
		if (self.popupWindow.mouseInWindow) {
			if (self.active) {
				[self.popupWindow makeFullAlpha];
			}
		}
	}
	else {
		[self updatePopupStyle];
	}
}

- (void)cancelPopup:(BOOL)quick
{
    // always cancel popup
    [self cancelTip];
    
	if (!_cancelled)
	{        
        NMLogFine(@"Cancelling popup (%d)", quick);
        
		// stop detecting mouse leaving box
		[self stopBoxDetect];

        // stop observing buttons
        for (NMPopupWindowButton *button in _currentButtons) {
            button.mouseInsideButton=NO;
            button.activeButton=NO;
            [button removeObserver:self forKeyPath:@"mouseInsideButton"];
        }
        _currentButtons=nil;
        
        [self.popupWindow fadeOutQuickly:quick];
        
        [NSEvent removeMonitor:_monitor];
        _monitor=nil;
        _scrollDistance=0.0;
        
		// set as cancelled and inactive
		_cancelled=YES;
		_active=NO;        
	}
}

- (NMPopupWindowButton *)newButtonWithTitle:(NSString *)title image:(NSImage *)image cancels:(BOOL)cancels targetBlock:(NMBasicBlock)block
{
    NMPopupWindowButton *result=[[NMPopupWindowButton alloc] initWithFrame:NSZeroRect];
    __unsafe_unretained NMPopupController *selfWeak=self;
    __unsafe_unretained NMPopupWindowButton *weakButton=result;
    [result setTargetBlock:^{
        [selfWeak cancelTip];
        _lastClickedButtonFrame=[weakButton frame];
        _lastClickedButtonFrame.origin.x+=[[weakButton window] frame].origin.x;
        _lastClickedButtonFrame.origin.y+=[[weakButton window] frame].origin.y;
        [weakButton flash];
        if (cancels||_popupWindow.keyboardMode) {
            [selfWeak notifyAbortWithReason:NMPopupReasonActionSelected];
            [selfWeak cancelPopup:_popupWindow.keyboardMode];
        }
        
        block();
    }];
    [result setTitle:title];
    [result setImage:image];
    return result;
}

- (NMPopupWindowButton *)newButtonWithTitle:(NSString *)title image:(NSImage *)image targetBlock:(NMBasicBlock)block
{
    return [self newButtonWithTitle:title image:image cancels:YES targetBlock:block];
}

- (void)doPopupWithButtons:(NSArray *)buttons location:(NSPoint)location keyboardMode:(BOOL)kbmode activeButton:(NMPopupWindowButton *)presetActiveButton
{
    if (self.cancelled) {
		return;
	}

    _currentButtons=buttons;    
    _currentLocation=location;

    NMPopupWindowButton *first=nil;
    NMPopupWindowButton *last=nil;    
    NMPopupWindowButton *prev=nil;     
    NMPopupWindowButton *firstActive=nil;
    for (NMPopupWindowButton *b in _currentButtons) {
        if (!first) {
            first=b;
        }
        if (!firstActive&&[b isEnabled]) {
            firstActive=b;
        }
        b.popupButtonDelegate=self;
        b.prevButton=prev;
        prev.nextButton=b;
        prev=b;
        last=b;
        
        // observe mouse inside
        [b addObserver:self forKeyPath:@"mouseInsideButton" options:0 context:0];
    }
    
    first.prevButton=last;
    last.nextButton=first;
    if (kbmode) {    
        _activeButton=presetActiveButton?presetActiveButton:firstActive;
    }
    
    first.leftmost=YES;
    last.rightmost=YES;
    
    // prepare popup window (but dont's show)
	[_popupWindow preparePopupWithButtons:buttons nubLocation:_currentLocation];
    
    // adjust location if nubless
    if (self.nubless) {
        location.y+=([_popupWindow nubPosition]==NMNubPositionBottom?1:-1)*[NMPopupWindowButton nubSize];
        _popupWindow.nubLocation=location;
    }
	   
	// start detection of mouse leaving box
    [self startBoxDetect];
    
    _monitor=[NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask|NSLeftMouseDraggedMask|NSRightMouseDraggedMask|NSOtherMouseDraggedMask|NSLeftMouseDownMask|NSRightMouseDownMask|NSOtherMouseDownMask|NSKeyDownMask|NSScrollWheelMask
                                                    handler:^(NSEvent *event) {                                                     
                                                        NSEventMask mask=NSEventMaskFromType(event.type);
                                                        if (mask&(NSMouseMovedMask|NSLeftMouseDraggedMask|NSRightMouseDraggedMask|NSOtherMouseDraggedMask)) {
                                                            [self checkBoxWithPoint:[NSEvent mouseLocation]];
                                                        }
                                                        else if (mask&(NSLeftMouseDownMask|NSRightMouseDownMask|NSOtherMouseDownMask)) {
                                                            if(!self.mouseActiveInPopup) {
                                                                [self notifyAbortWithReason:NMPopupReasonMouseClick];
                                                                [self cancelPopup];
                                                            }
                                                        }
                                                        else if (mask&NSScrollWheelMask) {
                                                            _scrollDistance+=fabs([event deltaX])+fabs([event deltaY]);
                                                            if(_scrollDistance>=3.0) {
                                                                [self notifyAbortWithReason:NMPopupReasonScrollWheel];
                                                                [self cancelPopup];
                                                            }
                                                        }
                                                        else if (mask&NSKeyDownMask) {
                                                            if (!_popupWindow.keyboardMode) {
                                                                [self notifyAbortWithReason:NMPopupReasonKeyPress];
                                                                [self cancelPopup];
                                                            }
                                                        }
                                                        else {
                                                            [self notifyAbortWithReason:NMPopupReasonOther];
                                                            [self cancelPopup];
                                                        }
                                                    }];
	
    // send notifications
    [(NSDistributedNotificationCenter *)[NSDistributedNotificationCenter defaultCenter]
     postNotificationName:NMPopupWillAppearGlobalNotification
     object:_noteObjectString
     userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:NMPopupWillAppearNotification object:self];
    
	// show the popup
	_active=YES;
        
	[_popupWindow showPopupInKeyboardMode:kbmode];
    
    // set full alpha if already moved into frame
    BOOL mouseInAlready=NSPointInRect([NSEvent mouseLocation], NSInsetRect([self.popupWindow frame], 1, 1));
    if (mouseInAlready) {
        [_popupWindow mouseEntered:[NSApp currentEvent]];
        for (NMPopupWindowButton *v in buttons) {
            if (NMMouseInView(v)) {
                [v mouseEntered:[NSApp currentEvent]];
            }
        }
    }
    if (mouseInAlready) {
        [_popupWindow makeFullAlpha];
    }
}

- (void)doPopupWithButtons:(NSArray *)buttons location:(NSPoint)location
{
    [self doPopupWithButtons:buttons location:location keyboardMode:NO activeButton:nil];
}

- (void)doPopupWithButtons:(NSArray *)buttons
{
    [self doPopupWithButtons:buttons location:[[NMPoint currentUnflippedMouseLocation] nsPoint] keyboardMode:NO activeButton:nil];
}

- (void)cancelPopup
{
	[self cancelPopup:NO];
}

- (void)prepareNew
{
    [self cancelPopup];
    _cancelled=NO;
}

- (BOOL)isMouseActiveInPopup
{
	return _mouseButton&&_active&&!_cancelled;
}

- (BOOL)isMouseInPopup
{
	return _popupWindow.mouseInWindow&&_active&&!_cancelled;
}

- (BOOL)isAlive
{
	return _active&&!_cancelled;
}

- (void)popupKeyDown:(NSEvent *)theEvent
{
    CGKeyCode key=[theEvent keyCode];
    switch (key) {
        case kVK_Escape:
            [self cancelPopup];
            break;
            
        case kVK_Return:
        case kVK_Space:
        {
            NMBasicBlock block=[_activeButton target];
            if (block) {
                block();
            }
        }
            break;
            
        case kVK_LeftArrow:
        case kVK_UpArrow:
        case kVK_ANSI_H:
        case kVK_ANSI_K:
        {
            if ([_activeButton tag]==99) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"                
                [[_activeButton target] performSelector:[_activeButton action]];
#pragma clang diagnostic pop    
            }
            else {
                NMPopupWindowButton *initial=_activeButton;
                do {
                    _activeButton=_activeButton.prevButton;                
                } while (_activeButton!=initial&&![_activeButton isEnabled]);
                [_popupWindow display];                
            }
        }
            break;
            
        case kVK_RightArrow:
        case kVK_DownArrow:
        case kVK_ANSI_L:
        case kVK_ANSI_J:
        {
            if ([_activeButton tag]==101) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [[_activeButton target] performSelector:[_activeButton action]];
#pragma clang diagnostic pop
            }
            else {            
                NMPopupWindowButton * initial=_activeButton;
                do {
                    _activeButton=_activeButton.nextButton;                
                } while (_activeButton!=initial&&![_activeButton isEnabled]);
                [_popupWindow display];                 
            }
        }
            break;                        

        default:
            [self cancelPopup];            
            break;
    }    
}

- (void)popupKeyUp:(NSEvent *)theEvent
{

}

- (BOOL)isButtonActive:(NMPopupWindowButton *)button
{
    return [_activeButton isEqual:button];
}

- (void)makeButtonActive:(NMPopupWindowButton *)button
{
    _activeButton=button;
}

- (BOOL)shouldButtonRelinquishActive:(NMPopupWindowButton *)button
{
    return !_popupWindow.keyboardMode;
}

- (void)mouseEnteredButton:(NMPopupWindowButton *)button
{
    [_tipCancelTimer invalidate];
    [_tipTimer invalidate];
    if ([[button tip] length]>0&&![[NSUserDefaults standardUserDefaults] boolForKey:@"DisableToolTips"]) {
        _tipTimer=[NSTimer scheduledTimerWithTimeInterval:_isShowingTip?0.1:1.0 block:^{
            if ([self isMouseActiveInPopup]) {
                _isShowingTip=YES;
                [self showTipText:[button tip]];
            }
            else {
                [self cancelTip];
            }
        } repeats:NO];
    }
    else {
        [_tipWindow animateAlphaTo:0.0 duration:0.15];
    }
}

- (void)mouseExitedButton:(NMPopupWindowButton *)button
{
    [_tipTimer invalidate];
    [_tipCancelTimer invalidate];
    _tipCancelTimer=[NSTimer scheduledTimerWithTimeInterval:0.1 block:^{
        [self cancelTip];
    } repeats:NO];
}

- (void)showTipText:(NSString *)text
{
    [_tipWindow prepareWithText:text andLocation:[[NMPoint currentUnflippedMouseLocation] nsPoint]];
    [_tipWindow display];
    [_tipWindow makeKeyAndOrderFront:self];
    [_tipWindow animateAlphaTo:1.0 duration:0.02];
}

- (void)cancelTip
{
    NMLogFine(@"Cancel tool tip");
    [_tipTimer invalidate];
    _isShowingTip=NO;
    [_tipWindow animateAlphaTo:0.0 duration:0.15];
}

- (void)notifyAbortWithReason:(NSString *)reason
{
    NSDictionary *userInfo=@{NMPopupBoxKey: [NSValue valueWithRect:_box], NMPopupReasonKey: reason};
    [[NSNotificationCenter defaultCenter] postNotificationName:NMPopupDidCancelNotification object:self userInfo:userInfo];
}

@end
