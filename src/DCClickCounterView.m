// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCClickCounterView.h"
#import "DCEngine+Gubbins.h"
#import "DCConstants.h"

static NSMutableDictionary *_textAttr;
static NSMutableDictionary *_titleAttr;
static NSMutableDictionary *_buttonAttr;
static NSString *_title=@"Clicks";
static NSString *_buttonTitle=@"Reset";
static NSShadow *_shadow;
static NSSize _digitSize;
static NSSize _titleSize;
static NSSize _buttonSize;

static NSString *oldDigits;
static NSString *digits;

@interface DCClickCounterView ()
- (void)timerRoutine;
@end

@implementation DCClickCounterView

+ (void)initialize
{
	if (self==[DCClickCounterView class]) {
		_shadow=[[NSShadow alloc] init];
		[_shadow setShadowColor:[NSColor colorWithDeviceWhite:0 alpha:0.5]];
		[_shadow setShadowBlurRadius:3.0];
		[_shadow setShadowOffset:NSMakeSize(0, 0)];
		
		_textAttr=[[NSMutableDictionary alloc] init];
		_textAttr[NSForegroundColorAttributeName] = [NSColor whiteColor];
		_textAttr[NSFontAttributeName] = [NSFont boldSystemFontOfSize:15];
		_textAttr[NSShadowAttributeName] = _shadow;

		_titleAttr=[[NSMutableDictionary alloc] init];
		_titleAttr[NSForegroundColorAttributeName] = [NSColor colorWithDeviceWhite:1.0 alpha:0.5];
		_titleAttr[NSFontAttributeName] = [NSFont systemFontOfSize:12];
		_titleAttr[NSShadowAttributeName] = _shadow;
		
		
		_buttonAttr=[[NSMutableDictionary alloc] init];
		_buttonAttr[NSForegroundColorAttributeName] = [NSColor colorWithDeviceWhite:1.0 alpha:0.5];
		_buttonAttr[NSFontAttributeName] = [NSFont systemFontOfSize:12];
		_buttonAttr[NSShadowAttributeName] = _shadow;
		
		_digitSize=[@"0" sizeWithAttributes:_textAttr];
		_titleSize=[_title sizeWithAttributes:_titleAttr];
        _titleSize.width+=4;
		_buttonSize=[_buttonTitle sizeWithAttributes:_buttonAttr];
        _buttonSize.width+=16;
	}
}


static CGFloat _w;//=200;
static const CGFloat _h=30;
static const CGFloat _vpad=5;
static const CGFloat _hpad=6;
static const CGFloat _numw=14;
static const CGFloat _numh=20;
static const CGFloat _numpad=2;
static const CGFloat _butpad=5;
static const CGFloat _buth=20;
static const CGFloat _titlepad=5;
static NSUInteger _buttonCount=10;
static const NSUInteger _frames=5;
static const NSTimeInterval _speed=0.02;

- (NSString *)clicksDigits
{
	return [NSString stringWithFormat:@"%010qu", [DCEngine sharedInstance].dwellClickCount];
}

- (void)setColors
{
	unsigned long long count=[DCEngine sharedInstance].dwellClickCount;
	if (count>=1000000000) {
		_buttonCount=9;
		_textAttr[NSForegroundColorAttributeName] = [NSColor redColor];
	}
	else if (count>=100000000) {
		_buttonCount=9;
		_textAttr[NSForegroundColorAttributeName] = [NSColor greenColor];
	}
	else if (count>=10000000) {
		_buttonCount=8;
		_textAttr[NSForegroundColorAttributeName] = [NSColor cyanColor];
	}
	else if (count>=1000000) {
		_buttonCount=7;
		_textAttr[NSForegroundColorAttributeName] = [NSColor yellowColor];
	}
	else if (count>=100000) {
		_buttonCount=6;
		_textAttr[NSForegroundColorAttributeName] = [NSColor whiteColor];
	}
	else {
		_buttonCount=6;
		_textAttr[NSForegroundColorAttributeName] = [NSColor whiteColor];
	}
	
	_w=_numpad+2*_hpad+_titleSize.width+_buttonCount*(_numpad+_numw)+_buttonSize.width+_butpad+_titlepad;
	[resetButton setFrame:NSMakeRect(_numpad+_hpad+_titleSize.width+_buttonCount*(_numw+_numpad)+_butpad+_titlepad, _vpad, _buttonSize.width, _buth)];
}

- (id)initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect];
	if (self) {
		
		[self addObserver:self forKeyPath:@"clicksDigits" options:0 context:0];
		resetButton=[[NMSugarButton alloc] initWithFrame:NSZeroRect];
        [resetButton setTitle:_buttonTitle];
        [resetButton setBackgroundColor:[NSColor blackColor]];
		[resetButton setTarget:self];
		[resetButton setAction:@selector(resetClickCounts:)];
		
		[self setColors];
		oldDigits=digits=[self clicksDigits];
		[self addSubview:resetButton];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self setColors];
	if ([[self window] isVisible]) {		
		digits=[self clicksDigits];
		frame=0;
		if (!timer) {
			timer=[NSTimer timerWithTimeInterval:_speed target:self selector:@selector(timerRoutine) userInfo:0 repeats:YES];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
		}
	}
}

-(void)drawDigit:(NSString *)digit old:(NSString *)old inRect:(NSRect)rect trans:(CGFloat)trans
{
	CGFloat roundedRadius = 0.0f;
	[NSGraphicsContext saveGraphicsState];
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:roundedRadius yRadius:roundedRadius];
	[path addClip];
	
	// fill background	
	NSColor *startColor  = [NSColor colorWithDeviceWhite:0.03 alpha:1.0];
	NSColor *endColor    = [NSColor colorWithDeviceWhite:0.02 alpha:1.0];
	NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:startColor, 0.0, endColor, 1.0, nil];
	[gradient drawInBezierPath:path angle:90];
	
	// draw text
	CGFloat off=[old isEqualToString:digit]?0:trans*_numh;
	NSPoint pt=NSMakePoint(rect.origin.x+(rect.size.width-_digitSize.width)*0.5, rect.origin.y+(rect.size.height-_digitSize.height)*0.5+off);
	NSPoint downpt=NSMakePoint(rect.origin.x+(rect.size.width-_digitSize.width)*0.5, rect.origin.y+(rect.size.height-_digitSize.height)*0.5+off-_numh);
	[old drawAtPoint:pt withAttributes:_textAttr];
	[digit drawAtPoint:downpt withAttributes:_textAttr];

	
	// draw the gradient
	NSRect gradBounds = rect;
	gradBounds.size.height*=0.5;
	gradBounds.origin.y+=gradBounds.size.height;
	[[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.06]
								   endingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.30]]
	 drawInRect:gradBounds angle:90];
	
	// draw the shadow
	gradBounds = rect;
	gradBounds.size.height*=0.5;
	gradBounds.origin.y+=gradBounds.size.height;
	[[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0 alpha:0.0]
								   endingColor:[NSColor colorWithDeviceWhite:0 alpha:0.3]]
	 drawInRect:gradBounds angle:90];
	// draw the shadow
	gradBounds = rect;
	gradBounds.size.height*=0.5;
	//gradBounds.origin.y+=gradBounds.size.height;
	[[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0 alpha:0.3]
								   endingColor:[NSColor colorWithDeviceWhite:0 alpha:0.0]]
	 drawInRect:gradBounds angle:90];
	
	
	[NSGraphicsContext restoreGraphicsState];
}

-(void)drawRect:(NSRect)dirtyRect
{
	NSRect boxRect=NSMakeRect(0, 0, _w, _h);
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:boxRect xRadius:5.0 yRadius:5.0];
	
	// fill background	
	NSColor *startColor  = [NSColor colorWithDeviceWhite:0.1 alpha:1.0];
	NSColor *endColor    = [NSColor colorWithDeviceWhite:0.05 alpha:1.0];
	NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:startColor, 0.0, endColor, 1.0, nil];
	[gradient drawInBezierPath:path angle:90];
	
	// draw the gradient
	NSRect gradBounds = boxRect;
	gradBounds.size.height*=0.5;
	gradBounds.origin.y+=gradBounds.size.height;
	[[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.06]
								   endingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.35]]
	 drawInRect:gradBounds angle:90];
	
	// draw text
	NSPoint pt=NSMakePoint(_hpad, boxRect.origin.y+(boxRect.size.height-_titleSize.height)*0.5);
	[_title drawAtPoint:pt withAttributes:_titleAttr];
	
	// draw number box
	[NSGraphicsContext saveGraphicsState];
	NSRect numBox=NSMakeRect(_hpad+_titleSize.width+_titlepad, _vpad, (_numw+_numpad)*_buttonCount+_numpad, _numh);
	NSBezierPath *numPath = [NSBezierPath bezierPathWithRoundedRect:numBox xRadius:2.0 yRadius:2.0];
	[numPath addClip];
	startColor  = [NSColor colorWithDeviceWhite:0.03 alpha:1.0];
	endColor    = [NSColor colorWithDeviceWhite:0.02 alpha:1.0];
	gradient = [[NSGradient alloc] initWithColorsAndLocations:startColor, 0.0, endColor, 1.0, nil];
	[gradient drawInBezierPath:numPath angle:90];
	
	// draw the numbers
	for(NSUInteger i=0; i<_buttonCount; i++)
	{
		NSString *digit=[digits substringWithRange:NSMakeRange((10-_buttonCount)+i, 1)];
		[self drawDigit:digit old:[oldDigits substringWithRange:NSMakeRange((10-_buttonCount)+i, 1)] inRect:NSMakeRect(_numpad+_hpad+_titleSize.width+_titlepad+i*(_numw+_numpad), _vpad, _numw, _numh) trans:frame/(_frames*1.0)];
	}
	
	// draw shadow
	[[NSColor colorWithDeviceWhite:0 alpha:0.5] setStroke];
	[numPath stroke];
	[NSGraphicsContext restoreGraphicsState];
	
	// draw edge
	[[[NSColor whiteColor] colorWithAlphaComponent:0.1] set];
	[path setLineWidth:2.0];
	[path addClip];
	[path stroke];
}

- (void)timerRoutine
{
	if (frame==_frames) {
		oldDigits=digits;
		[timer invalidate];
		timer=nil;
	}
	else {
		frame++;
		[self setNeedsDisplay:YES];
	}
}

- (id)engine
{
	return [DCEngine sharedInstance];
}

+ (NSSet *)keyPathsForValuesAffectingClicksDigits
{
	return [NSSet setWithObjects:@"engine.dwellClickCount", nil];
}

- (IBAction)resetClickCounts:(id)sender
{
	oldDigits=@"9999999999";
	[[self engine] resetClickCounts];
}

@end
