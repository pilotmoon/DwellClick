// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCScrollDetector.h"
#import "DCBoxGrab.h"

#define PIXELS 15
#define SIZE ((PIXELS*2)-1)
#define MIDDLE (SIZE/2)
#define SCANOFF 10

/*
 // THE OLD CODE
#define BYTEWIDTH (SIZE*4)
#define BUFFERSIZE (SIZE*BYTEWIDTH)

// snow leopard
#define START_GREY 0xb7b7b7ff
#define END_GREY_1 0x5d5d5dff
#define END_GREY_2 0xadadadff

// leopard
#define START_GREY_L 0xabababff
#define END_GREY_1_L 0x5c5c5cff
#define END_GREY_2_L 0xabababff


// this looks if the pixesl under the mouse look like a scroll bar
// hard coded to the standard for snow leopard blue and graphite schemes
// will break if apple change the ui rendering
Boolean isScroll(uint32_t *buffer)
{
	// first look for grey 2
	int i=MIDDLE;
	for (; i<SIZE; i++)
	{
		if (buffer[i]==END_GREY_2||buffer[i]==END_GREY_2_L) break;
	}
	if (i==SIZE) return FALSE; // not found
	MSG(Found end grey 2);
	if (buffer[i-1]!=END_GREY_1 && buffer[i-1]!=END_GREY_1_L) return FALSE;
	MSG(Found end grey 1);
	if (buffer[i-14]!=START_GREY && buffer[i-14]!=START_GREY_L) return FALSE;
	MSG(Found start grey);
	//printf("start color is 0x%08x\n",buffer[i-13]);
	
	//if (buffer[i-13]!=START_COLOR&&buffer[i-13]!=START_GRAPHITE) return false;
	// start color can vary go by "luminance" (should be dark)
	// only detects acrive scroll bars (blue orgraphite) add lum values 474, 482, 489, 492 for unsel
	const unsigned char *p=(const unsigned char *)(buffer+(i-13));
	uint32_t lum=p[1]+p[2]+p[3];
	//printf("lum is %d\n", lum);
	if(!(lum<300&&lum>150)) return FALSE;

	MSG(Found start color);
	return TRUE;
}*/

// full set patterns for snow leopard blue
#define NUM_PATTERNS
#define PATTERN_LENGTH 15
static CGFloat _patterns[NUM_PATTERNS][PATTERN_LENGTH]= {
	{0.8118, 0.4392, 0.7477, 0.8065, 0.8000, 0.7817, 0.6654, 0.7124, 0.7529, 0.7961, 0.8314, 0.8549, 0.8340, 0.5765, 0.7856},
	/*{0.8118, 0.4392, 0.7464, 0.8052, 0.7961, 0.7778, 0.6601, 0.7085, 0.7503, 0.7869, 0.8183, 0.8497, 0.8314, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7399, 0.8013, 0.7908, 0.7778, 0.6471, 0.6993, 0.7425, 0.7804, 0.8131, 0.8392, 0.8248, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7399, 0.7948, 0.7908, 0.7725, 0.6431, 0.6863, 0.7333, 0.7725, 0.8065, 0.8366, 0.8144, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7386, 0.7948, 0.7791, 0.7621, 0.6314, 0.6784, 0.7229, 0.7647, 0.7974, 0.8222, 0.7974, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7438, 0.7922, 0.7882, 0.7647, 0.6405, 0.6902, 0.7320, 0.7699, 0.8000, 0.8314, 0.8092, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7399, 0.8013, 0.7869, 0.7739, 0.6458, 0.6928, 0.7399, 0.7817, 0.8105, 0.8392, 0.8144, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7425, 0.8052, 0.7974, 0.7778, 0.6588, 0.7059, 0.7516, 0.7869, 0.8196, 0.8497, 0.8301, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7438, 0.8105, 0.8000, 0.7908, 0.6641, 0.7124, 0.7582, 0.7922, 0.8275, 0.8510, 0.8353, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7464, 0.8144, 0.8052, 0.7922, 0.6745, 0.7176, 0.7595, 0.8013, 0.8353, 0.8588, 0.8340, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7556, 0.8144, 0.8039, 0.7948, 0.6771, 0.7255, 0.7660, 0.8052, 0.8366, 0.8706, 0.8484, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7595, 0.8131, 0.8118, 0.7961, 0.6850, 0.7346, 0.7765, 0.8157, 0.8484, 0.8732, 0.8484, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7490, 0.8157, 0.8131, 0.8013, 0.6954, 0.7412, 0.7804, 0.8183, 0.8497, 0.8810, 0.8601, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7503, 0.8196, 0.8157, 0.7987, 0.6876, 0.7307, 0.7739, 0.8170, 0.8458, 0.8732, 0.8510, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7477, 0.8170, 0.8092, 0.7961, 0.6771, 0.7229, 0.7647, 0.8078, 0.8431, 0.8680, 0.8484, 0.5765, 0.7856},
	{0.8118, 0.4392, 0.7477, 0.8118, 0.8052, 0.7895, 0.6706, 0.7203, 0.7608, 0.8013, 0.8327, 0.8614, 0.8405, 0.5765, 0.7856},*/
};


static CGFloat _squares(const CGFloat *const buf, const CGFloat *const pattern)
{
	CGFloat result=0;
	// scale factor for normalization 
	CGFloat factor=pattern[PATTERN_LENGTH/2]/buf[PATTERN_LENGTH/2];
	// dont normalize 2 pixels at each end
	CGFloat diff=pattern[0]-(buf[0]);
	result+=diff*diff;
	diff=pattern[1]-(buf[1]);
	result+=diff*diff;
	diff=pattern[13]-(buf[13]);
	result+=diff*diff;
	diff=pattern[14]-(buf[14]);
	result+=diff*diff;
	// the rest
	for(int i=2; i<13; i++)
	{
		diff=pattern[i]-(buf[i]*factor);
		result+=diff*diff;
	}
	return result;
}

static CGFloat leastSquareMatch(const CGFloat *const line, const CGFloat *const pattern)
{
	CGFloat least=_squares(line, pattern);
	for(int i=1; i<PATTERN_LENGTH; i++)
	{
		CGFloat squares=_squares(line+i, pattern);
		if (squares<least) {
			least=squares;
		}
	}
	return least;
}

static BOOL _isScroll(const CGFloat *const bwdata)
{
	CGFloat least=leastSquareMatch(bwdata, _patterns[0]);
	return (least<0.015);
}


// make black and white
static void _makeBW(NSData *data, CGFloat *outbuf)
{
	NSUInteger newLen=[data length]/4;
	const uint32_t *inbuf=[data bytes];
	for(NSUInteger i=0; i<newLen; i++, inbuf++, outbuf++)
	{
		uint8_t *bytes=(unsigned char *)inbuf;
		CGFloat temp=bytes[0];
		temp+=bytes[1];
		temp+=bytes[2];
		*outbuf=temp/(255*3);
	}
}

BOOL DCScrollBarAtPoint(NSPoint point)
{		
	NSData *data=DCBoxDataAtPoint(point, PIXELS);
	if(!data) {
		NMLogInfo(@"Couldnt get box");
		return FALSE;
	}
	
	CGFloat bwdata[SIZE*SIZE];
	_makeBW(data, bwdata);
	
	// examine rows then columns
	for(int row=MIDDLE-SCANOFF; row<=MIDDLE+SCANOFF; row++)
	{
		if(_isScroll(bwdata+(row*SIZE))) return TRUE;		
	}
	for(int col=MIDDLE-SCANOFF; col<=MIDDLE+SCANOFF; col++)
	{
		CGFloat temp[SIZE];
		CGFloat *iter=temp+SIZE; // reverse it for easier scanning for scroll
		for(int i=0; i<SIZE; i++)
		{
			*--iter=(bwdata)[i*SIZE+col];
		} 
		if(_isScroll(temp)) return TRUE;		
	}

	return FALSE;
}
