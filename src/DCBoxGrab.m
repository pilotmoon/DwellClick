// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCBoxGrab.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>


/*
 * Given a display ID and a rectangle on that display, get crosshairs at center
 * of rectangle. srcRect should be have odd sized sides.
 *
 * srcRect is display-origin relative.
 *
 * This function uses a full screen OpenGL read-only context.
 * By using OpenGL, we can read the screen using a DMA transfer
 * when it's in millions of colors mode, and we can correctly read
 * a microtiled full screen OpenGL context, such as a game or full
 * screen video display.
 *
 * Returns NULL on an error, returns buffer on success
 */
/*
 * NM Modified from:
 * glGrab.c
 * Found in http://lists.apple.com/archives/cocoa-dev/2005/Aug/msg00901.html
 * Fix for Intel processors: http://lists.apple.com/archives/quartz-dev/2006/May/msg00100.html
 */
static void *grabBoxViaOpenGL(CGDirectDisplayID display, CGRect srcRect, void *data)
{
	CGContextRef bitmap;
	CGLContextObj glContextObj;
	CGLPixelFormatObj pixelFormatObj;
	GLint numPixelFormats;
	CGOpenGLDisplayMask displayMask=CGDisplayIDToOpenGLDisplayMask(display);
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	CGLPixelFormatAttribute attribs[] =
	{
		kCGLPFAFullScreen,
		kCGLPFADisplayMask,
		displayMask,
		0
	};
#pragma clang diagnostic pop
	
	/* Build a full-screen GL context */
	CGLChoosePixelFormat( attribs, &pixelFormatObj, &numPixelFormats );
	if ( pixelFormatObj == NULL )    // No full screen context support
		return NULL;
	CGLCreateContext( pixelFormatObj, NULL, &glContextObj ) ;
	CGLDestroyPixelFormat( pixelFormatObj ) ;
	if ( glContextObj == NULL )
		return NULL;
	
	
	CGLSetCurrentContext( glContextObj ) ;
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	CGLSetFullScreen( glContextObj ) ;  // deprecated warning	
#pragma clang diagnostic pop
	

	
	glReadBuffer(GL_FRONT);
	
	CGColorSpaceRef cSpace = CGColorSpaceCreateWithName (kCGColorSpaceGenericRGB);
	bitmap = CGBitmapContextCreate(data, srcRect.size.width, srcRect.size.height, 8, srcRect.size.width*4,
								   cSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst /* XRGB */); /*TODO this is wrong? */
	CFRelease(cSpace);
	
	
	/* Read framebuffer into our bitmap */
	glFinish(); /* Finish all OpenGL commands */
	glPixelStorei(GL_PACK_ALIGNMENT, 4); /* Force 4-byte alignment */
	glPixelStorei(GL_PACK_ROW_LENGTH, 0);
	glPixelStorei(GL_PACK_SKIP_ROWS, 0);
	glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
	
	/*
	 * Fetch the data in XRGB format, matching the bitmap context.
	 */
	glReadPixels((GLint)srcRect.origin.x, (GLint)srcRect.origin.y, srcRect.size.width, srcRect.size.height,
				 GL_BGRA,
#ifdef __BIG_ENDIAN__
				 GL_UNSIGNED_INT_8_8_8_8_REV, // for PPC
#else
				 GL_UNSIGNED_INT_8_8_8_8, // for Intel! http://lists.apple.com/archives/quartz-dev/2006/May/msg00100.html
#endif
				 data);
	
	/* Get rid of bitmap */
	CFRelease(bitmap);
	
	/* Get rid of GL context */
	CGLSetCurrentContext( NULL );
	CGLClearDrawable( glContextObj ); // disassociate from full screen
	CGLDestroyContext( glContextObj ); // and destroy the context
	
	/* Returned image has a reference count of 1 */
	return data;
}

Boolean DCBoxAtPoint(CGPoint point, uint32_t *data, CGFloat box_size)
{
	// get the display that the point is in
	CGDirectDisplayID display=0;
	CGDisplayCount count=0;
	CGDisplayErr error=CGGetDisplaysWithPoint(point, 1, &display, &count);
	if (error!=CGDisplayNoErr && count!=1) {
		//NMLogInfo(@"Cant get display");
		return FALSE;
	}
	//printf("Display id is %d\n", display);
	
	// get point flipped in local coords
	CGRect bounds=CGDisplayBounds(display);
	point.x=point.x-bounds.origin.x;
	point.y=bounds.size.height-(point.y-bounds.origin.y);
	
	// make bounds local too
	bounds.origin=CGPointMake(0, 0);
	
	// get our square
	CGFloat side=box_size;
	CGFloat offset=side*0.5;
	CGRect square=CGRectMake(point.x-offset, point.y-offset-1, side, side);
	//printf("local square is: %f, %f : %f, %f\n", square.origin.x, square.origin.y, square.size.width, square.size.height);
	
	// get box
	return (NULL!=grabBoxViaOpenGL(display, square, data));
}

NSData *DCBoxDataAtPoint(NSPoint point, NSUInteger pixels) // pixels from center
{
	if (!(pixels>0&&pixels<100))
	{
		NMLogInfo(@"Bad Pixels Size");
		return nil;
	}
	NSUInteger box_side=(pixels*2)-1;
	size_t bufferSize=box_side*box_side*4;
	NSMutableData *result=[NSMutableData dataWithLength:bufferSize];
	void *buffer=[result mutableBytes];
	if(!DCBoxAtPoint(NSPointToCGPoint(point), buffer, box_side)) {
		NMLogInfo(@"Couldnt get box");
		return nil;
	}
	return result;
}

