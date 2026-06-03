// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCAnimationController.h"
#import "DCAnimationView.h"
#import "DCConstants.h"
#import "NSUserDefaults+Color.h"
#import "NMKit/NMKit.h"

#define BLANK_EXTRA 2

NSString *DCAnimWindowControllerAnimationStoppedNotification=@"DCAnimWindowControllerAnimationStoppedNotification";

@interface DCAnimationController (Private)
- (void)renderFrames;
- (void)stopFlashAnimation;
@end

@implementation DCAnimationController
@synthesize animView, throb;

#define FRAMES 8
#define DBL_EXTRA 5
#define DOWN_FRAMES 4
#define THROB_FRAMES 8
#define UP_FRAMES 5
#define FRAME_RATE (50.0)
#define FRAME_INTERVAL (1.0/FRAME_RATE)

#pragma mark Timer management

- (void)positionWindow
{
	NSPoint point=[[NMPoint currentUnflippedMouseLocation] nsPoint];
	point.x-=boxSide/2;
	point.y-=boxSide/2;
	[window setFrameOrigin:point];	
	[animView setNeedsDisplay:YES];
}

- (void)registerDrawBlockForKey:(id)key block:(NMBasicBlock)block
{
	if (!(animView.timerBlocks)[key]) {
		//NMLogInfo(@"adding block to timer");
		(animView.timerBlocks)[key] = [block copy];
		if (!timer) {
			//NMLogInfo(@"starting timer");
			[window setContentSize:NSMakeSize(boxSide, boxSide)];
			[self positionWindow];
			[window orderFront:self];
			timer=[NSTimer timerWithTimeInterval:FRAME_INTERVAL
                                          target:self
                                        selector:@selector(positionWindow)
                                        userInfo:nil
                                         repeats:YES];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
		}
	}
}

- (void)unregisterDrawBlockForKey:(id)key
{
	//NMLogInfo(@"removing block from timer");
	[animView.timerBlocks removeObjectForKey:key];
	if ([animView.timerBlocks count]==0) {
		//NMLogInfo(@"stopping timer");
		[timer invalidate];
		timer=nil;
		[window orderOut:self];
	}
}

- (BOOL)isDrawingKey:(id)key
{
    return !!(animView.timerBlocks)[key];
}

#pragma mark Direct pointer access

- (NSUInteger *)posPointer
{
	return &countdownPos;
}

- (NSUInteger *)hidePointer
{
	return &countdownHide;
}

#pragma mark Accessors

- (BOOL)animationOn
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsAnimationOn];
}

- (BOOL)countdownAnimationOn
{
	return [self animationOn] && [[NSUserDefaults standardUserDefaults] boolForKey:DCPrefsAnimationCountdownOn];
}

#pragma mark Initialization

// size has changed
- (void)updateParams
{
	float slider=[[[NSUserDefaults standardUserDefaults] valueForKey:DCPrefsAnimationSize] floatValue];
	if (slider<0.1) slider=0.1;
	if (slider>1.0) slider=1.0;
	
	boxSide=floor(slider*160.0)*2;
	speed=slider*10;
	downSpeed=slider*10;
}

- (id)init
{
	self=[super init];
	
	// create the window
	window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 10, 10)
                                         styleMask:NSBorderlessWindowMask
                                           backing:NSBackingStoreBuffered
                                             defer:YES];
	
	[window setContentView:[[NSImageView alloc] init]];
	[window setBackgroundColor:[NSColor clearColor]];
	[window setOpaque:NO];
	[window setLevel:NSScreenSaverWindowLevel];	
	[window setIgnoresMouseEvents:YES];
	
	// create view
	animView=[[DCAnimationView alloc] initWithFrame:NSZeroRect];
	[window setContentView:animView];
    
	// render the frames
	[self renderFrames];
	
	// set up observers     
    NMObservePrefsKeysUsingBlock(@[DCPrefsAnimationOn, DCPrefsAnimationColor, DCPrefsAnimationSize, DCPrefsDwellTimeSeconds], ^{
                                     if ([self animationOn]) {
                                         [self performSelector:@selector(renderFrames) withObject:nil afterDelay:0.1];
                                     }
                                     else {
                                         [self stopFlashAnimation];	
                                         [self stopCountdownAnimation];	
                                     }
                                 });
	
	return self;
}

#pragma mark Flash Animation Code

- (void)stopFlashAnimation
{
	[self unregisterDrawBlockForKey:@"main"];
    self.throb=NO;
	[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] postNotificationName:DCAnimWindowControllerAnimationStoppedNotification object:self];
}

- (void)animateFrames:(NSArray *)frames
{	
	// reset animation
	pos=0;
	currentAnimation=frames;
	[self registerDrawBlockForKey:@"main" block:^{		
		NSImage *img=nil;
		if (pos<[currentAnimation count])
		{
			img=currentAnimation[pos++];
		}
		else 
		{
			if (currentAnimation!=mouseDownFrames) 
			{				
				[self stopFlashAnimation];	
			}
			else {
                if (throb) {
                    img=throbFrames[pos-DOWN_FRAMES];
                    pos+=1;
                    if (pos>=DOWN_FRAMES+THROB_FRAMES) {
                        pos=DOWN_FRAMES;
                    }
                }
                else {
                    img=currentAnimation[[currentAnimation count]-1];
                }
			}
        }
		[img drawInRect:[animView bounds]
			   fromRect:NSZeroRect
			  operation:NSCompositeSourceOver
			   fraction:1.0];	
	}];
}

- (void)doFlashAnimationForClickType:(DCClickType)type
{
	if (![self animationOn]) {
		return;
	}
    animDirection=1;
	switch (type) {
		case DCClickTypeSingle:
			[self animateFrames:clickFrames];
			break;
		case DCClickTypeDouble:
			[self animateFrames:doubleClickFrames];
			break;
		case DCClickTypeTriple:
			[self animateFrames:tripleClickFrames];
			break;
		case DCClickTypeDragBegin:
			[self animateFrames:mouseDownFrames];
			break;
		case DCClickTypeDragEnd:
			[self animateFrames:mouseUpFrames];
			break;
		default:
			break;
	}	
}

#pragma mark Countdown Code

- (void)stopCountdownAnimation
{
	[self unregisterDrawBlockForKey:@"countdown"];
}

- (void)hideCountdownAnimation
{
	countdownHide=YES;
}

- (void)doCountdownAnimation
{
	if (![self countdownAnimationOn]) {
		return;
	}
	countdownPos=0;
	countdownHide=NO;
	[self registerDrawBlockForKey:@"countdown" block:^{
		if (!countdownHide)
		{
			if (countdownPos<[countDownFrames count])
			{
				[countDownFrames[countdownPos++] drawInRect:[animView bounds]
																  fromRect:NSZeroRect
																 operation:NSCompositeSourceOver
																  fraction:1.0];
			}
			else
			{
				[self stopCountdownAnimation];	
			}
		}
	}];
}

#pragma mark Rendering methods

- (NSColor *)haloColor
{
	return [[NSUserDefaults standardUserDefaults] colorForKey:DCPrefsAnimationColor];
}

- (NSColor *)haloColorWithAlpha:(CGFloat)alpha
{
	NSColor *convertedColor=[[self haloColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace]; // do this to avoid crash if user selects pure white color!
	return [NSColor colorWithDeviceRed:[convertedColor redComponent]
								 green:[convertedColor greenComponent]
								  blue:[convertedColor blueComponent]
								 alpha:alpha];
}

- (void)renderCountdownAnimationToArray:(NSArray *)array
{
    [NSGraphicsContext saveGraphicsState];     
	NSInteger frames=[array count];
	CGFloat countDownSpeed=(boxSide/2.5)/frames;
	for(NSInteger i=0; i<frames; i++)
	{			
		// set context
		NSImage *img=array[i];
		[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)[img representations][0]]];
		
		// draw halo		
		NSPoint center=NSMakePoint(boxSide/2, boxSide/2);
		CGFloat alpha=(0.9/frames)*(i-3);
		NSColor *start=[self haloColorWithAlpha:alpha];
		NSColor *end=[self haloColorWithAlpha:alpha*0.5];
		NSGradient *grad=[[NSGradient alloc] initWithStartingColor:start endingColor:end];
		CGFloat radius=countDownSpeed*(frames-i);
		[grad drawFromCenter:center
					  radius:radius
					toCenter:center
					  radius:radius*1.1+2
					 options:0];
	}
    [NSGraphicsContext restoreGraphicsState];        
}

- (void)renderMouseDownAnimationToArray:(NSArray *)array
{
    [NSGraphicsContext saveGraphicsState];     
	for(int i=0; i<DOWN_FRAMES; i++)
	{			
		// set context
		NSImage *img=array[i];
		[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)[img representations][0]]];
		
		// render glow
		NSPoint center=NSMakePoint(boxSide/2, boxSide/2);
		NSColor *start=[self haloColorWithAlpha:0.8];
		NSColor *end=[self haloColorWithAlpha:0.2];
		NSGradient *grad=[[NSGradient alloc] initWithStartingColor:start endingColor:end];
		[grad drawFromCenter:center
					  radius:0
					toCenter:center
					  radius:(i+1)*downSpeed
					 options:0];
	}
    [NSGraphicsContext restoreGraphicsState];        
}

- (void)renderThrobAnimationToArray:(NSArray *)array
{
    [NSGraphicsContext saveGraphicsState]; 
    static CGFloat off[]={2,1,0,-1,-2,-1,0,1};
	for(int i=0; i<THROB_FRAMES; i++)
	{			
        CGFloat radius=(DOWN_FRAMES+1)*downSpeed+(off[i]*0.6)-2.5;
        
		// set context
		NSImage *img=array[i];
		[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)[img representations][0]]];
		
		// render glow
		NSPoint center=NSMakePoint(boxSide/2, boxSide/2);
		NSColor *start=[self haloColorWithAlpha:0.8];
		NSColor *end=[self haloColorWithAlpha:0.2];
		NSGradient *grad=[[NSGradient alloc] initWithStartingColor:start endingColor:end];
		[grad drawFromCenter:center
					  radius:0
					toCenter:center
					  radius:radius
					 options:0];
	}
    [NSGraphicsContext restoreGraphicsState];        
}

- (void)renderMouseUpAnimationToArray:(NSArray *)array
{
    [NSGraphicsContext saveGraphicsState];    
	for(int i=0; i<UP_FRAMES; i++)
	{			
		// set context
		NSImage *img=array[i];
        
		[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)[img representations][0]]];
		
		// render glow
		NSPoint center=NSMakePoint(boxSide/2, boxSide/2);
		CGFloat alphaMul=1.0-(i*1.0)/UP_FRAMES;
		NSColor *start=[self haloColorWithAlpha:0.8*alphaMul];
		NSColor *end=[self haloColorWithAlpha:0.2*alphaMul];
		NSGradient *grad=[[NSGradient alloc] initWithStartingColor:start endingColor:end];
		[grad drawFromCenter:center
					  radius:0
					toCenter:center
					  radius:5*downSpeed+i*(downSpeed*0.5)
					 options:0];
        
	}
    [NSGraphicsContext restoreGraphicsState];            
}

- (void)renderClickAnimationToArray:(NSArray *)array atOffset:(NSUInteger)off
{
    [NSGraphicsContext saveGraphicsState];       
	for(int i=0; i<FRAMES; i++)
	{			
		// set context
		NSImage *img=array[i+off];
		[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)[img representations][0]]];
		
		// draw halo		
		NSPoint center=NSMakePoint(boxSide/2, boxSide/2);
		CGFloat alpha=(1.0/FRAMES)*(FRAMES-i);
		NSColor *end=[self haloColorWithAlpha:alpha];
		NSColor *start=[self haloColorWithAlpha:alpha*0.8];
		NSGradient *grad=[[NSGradient alloc] initWithStartingColor:start endingColor:end];
		[grad drawFromCenter:center
					  radius:0
					toCenter:center
					  radius:speed*(i+1)
					 options:0];
	}
    [NSGraphicsContext restoreGraphicsState];      
}

- (void)renderFrames
{	
	// click animation
	clickFrames=[NSMutableArray array];	
	[self updateParams];
	
	NMLogInfo(@"Rendering frames: boxSide is %f", boxSide);
	NSSize imageSize=NSMakeSize(boxSide, boxSide);	
	
	for(int i=0; i<FRAMES+BLANK_EXTRA; i++) { // +1 so last frame is blank
		[(NSMutableArray *)clickFrames addObject:[NSImage blankBitmapOfSize:imageSize]];
	}
	[self renderClickAnimationToArray:clickFrames atOffset:0];
	
	// double click animation
	doubleClickFrames=[[NSMutableArray alloc] initWithArray:clickFrames copyItems:YES];
	for(int i=0; i<DBL_EXTRA; i++) {
		[(NSMutableArray *)doubleClickFrames addObject:[NSImage blankBitmapOfSize:imageSize]];
	}
	[self renderClickAnimationToArray:doubleClickFrames atOffset:DBL_EXTRA];
	
	// double click animation
	tripleClickFrames=[[NSMutableArray alloc] initWithArray:doubleClickFrames copyItems:YES];
	for(int i=0; i<DBL_EXTRA; i++) {
		[(NSMutableArray *)tripleClickFrames addObject:[NSImage blankBitmapOfSize:imageSize]];
	}
	[self renderClickAnimationToArray:tripleClickFrames atOffset:DBL_EXTRA*2];
	
	// mouse down animation
	mouseDownFrames=[NSMutableArray array];	
	for(int i=0; i<DOWN_FRAMES; i++) {
		[(NSMutableArray *)mouseDownFrames addObject:[NSImage blankBitmapOfSize:imageSize]];
	}
	[self renderMouseDownAnimationToArray:mouseDownFrames];
	
    // throb animation
	throbFrames=[NSMutableArray array];	
	for(int i=0; i<THROB_FRAMES; i++) {
		[(NSMutableArray *)throbFrames addObject:[NSImage blankBitmapOfSize:imageSize]];
	}
	[self renderThrobAnimationToArray:throbFrames];
	
    
	// mouse up animation is reverse of mouse down
	mouseUpFrames=[NSMutableArray array];	
	for(int i=0; i<UP_FRAMES+BLANK_EXTRA; i++) {
		[(NSMutableArray *)mouseUpFrames addObject:[NSImage blankBitmapOfSize:imageSize]];
	}
	[self renderMouseUpAnimationToArray:mouseUpFrames];
	
	// count down animation
	countDownFrames=[NSMutableArray array];	
	int numCountDownFrames=[[NSUserDefaults standardUserDefaults] floatForKey:DCPrefsDwellTimeSeconds]/FRAME_INTERVAL;
	for(int i=0; i<numCountDownFrames; i++)
	{
		[(NSMutableArray *)countDownFrames addObject:[NSImage blankBitmapOfSize:imageSize]];
	}
	[self renderCountdownAnimationToArray:countDownFrames];
}

@end
