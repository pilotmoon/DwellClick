// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <AppKit/AppKit.h>
#import "NMCursorUtils.h"
#import "NMSuperFastHash.h"
#import "NMConfigUtils.h"

#ifdef DEBUG
#import "NMAppSupportDir.h"
#import "NMAppUtils.h"
#import "NMBlockUtils.h"
#endif

NSString *const NMCursorKnownHashes=@"NMCursorKnownHashes";
NSString *const NMCursorArrowHashes=@"NMCursorArrowHashes";
NSString *const NMCursorBeamHashes=@"NMCursorBeamHashes";
NSString *const NMCursorBlankHashes=@"NMCursorBlankHashes";

@implementation NSCursor (NMCursorUtils)

- (NSUInteger)superFastHash
{
#define SUPERFASTHASH_MAX_BYTES 16384 //64*64*4
    // get own image
    NSBitmapImageRep * const rep=(NSBitmapImageRep *)[[self image] representations][0];
    // the data
    const char * const data=(const char *)[rep bitmapData];
    // how many bytes
	const NSInteger bytesInImage=[rep bytesPerPlane]*[rep numberOfPlanes];
    // limit for safety
	const int bytesToCount=bytesInImage>SUPERFASTHASH_MAX_BYTES?SUPERFASTHASH_MAX_BYTES:(int)bytesInImage;
    // do hash
	return NMSuperFastHash(data,bytesToCount);
}

#ifdef DEBUG
- (void)log:(NSString *)string
{
    NSString *productName=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NMLogFine(@"product name %@", productName);
    NSString *asd=[NMAppSupportDir appSupportDirWithName:productName];
    if (asd) {
        NSError *error=nil;
        NSURL *file=[NSURL fileURLWithPathComponents:@[asd, @"KnownCursors.txt"]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:[file path]]) {
            [@"" writeToURL:file atomically:NO encoding:NSUTF8StringEncoding error:&error];
        }
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:file error:&error];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    }
}
#endif

// return hash, or placeholder if it's the standard arrow
- (NSNumber *)standardHashNum
{
    // static setup
    static NSMutableSet *arrowHashes=nil;
    static NSMutableSet *beamHashes=nil;
    static NSMutableSet *blankHashes=nil;
    static NSMutableSet *knownHashes=nil;
    static BOOL computedHashes=NO;
    if (!computedHashes) {
        // arrows
        arrowHashes=[NSMutableSet setFromArrayWithConfigName:NMCursorArrowHashes];
        [arrowHashes addObject:@([[NSCursor arrowCursor] superFastHash])];
        
        // beams
        beamHashes=[NSMutableSet setFromArrayWithConfigName:NMCursorBeamHashes];
        [beamHashes addObject:@([[NSCursor IBeamCursor] superFastHash])];        
        if ([NSCursor respondsToSelector:@selector(IBeamCursorForVerticalLayout)]) {
            NSCursor *cursor=[NSCursor performSelector:@selector(IBeamCursorForVerticalLayout)];
            [(NSMutableSet *)beamHashes addObject:@([cursor superFastHash])];
        }
        
        // blanks
        blankHashes=[NSMutableSet setFromArrayWithConfigName:NMCursorBlankHashes];
        
        // known
        knownHashes=[NSMutableSet setFromArrayWithConfigName:NMCursorKnownHashes];
        [knownHashes unionSet:arrowHashes];
        [knownHashes unionSet:beamHashes];
        [knownHashes unionSet:blankHashes];        
              
        NMLogTiny(@"Preset arrow hashes are %@.", arrowHashes);
        NMLogTiny(@"Preset beam hashes are %@.", beamHashes);
        NMLogTiny(@"Preset blank hashes are %@.", blankHashes);
        NMLogTiny(@"Preset known hashes are %@.", knownHashes);        
        
        computedHashes=YES;
    }
    
    NSNumber *const hash=@([self superFastHash]);
    NSNumber *result=hash;
    if ([arrowHashes containsObject:hash]) {
        result=[NSCursor standardArrowPlaceholder];
    }
    else if ([beamHashes containsObject:hash]) {
        result=[NSCursor standardBeamPlaceholder];
    }
    else if ([blankHashes containsObject:hash]) {
        result=[NSCursor standardBlankPlaceholder];
    }
    else if (![knownHashes containsObject:hash]) {
        // now it is known
        [knownHashes addObject:hash];
        [[NSUserDefaults standardUserDefaults] setObject:[knownHashes allObjects] forKey:NMCursorKnownHashes];

        // get simplified version
        NMSimplifiedCursor *const simple=[self simplifiedCursor];
        const BOOL isBeam=[simple isBeam];
        const BOOL isArrow=[simple isArrow];
        const BOOL isBlank=[simple isBlank];
        
#ifdef DEBUG
        NSString *logString=[NSString stringWithFormat:@"cursor: %@ %@ (%d,%d,%d) %@\n%@\n", hash, NSStringFromSize([[self image] size]), isBeam, isArrow, isBlank, NMBundleIdForPID(NMActiveApplicationPID()), [simple asciiArt]];
        NMLogFine(@"%@", logString);
        NMRunAsyncInBackground(^{[self log:logString];});
#endif
        
        if (isBeam) {
            [beamHashes addObject:hash];
            [[NSUserDefaults standardUserDefaults] setObject:[beamHashes allObjects] forKey:NMCursorBeamHashes];            
            result=[NSCursor standardBeamPlaceholder];
        }
        else if (isArrow) {
            [arrowHashes addObject:hash];
            [[NSUserDefaults standardUserDefaults] setObject:[arrowHashes allObjects] forKey:NMCursorArrowHashes];            
            result=[NSCursor standardArrowPlaceholder];
        }
        else if (isBlank) {
            [blankHashes addObject:hash];
            [[NSUserDefaults standardUserDefaults] setObject:[blankHashes allObjects] forKey:NMCursorBlankHashes];            
            result=[NSCursor standardBlankPlaceholder];
        }
    }

    NMLogTiny(@"Cursor pattern: %@", [[self simplifiedCursor] asciiArt]);
    NMLogTiny(@"Cursor classification is %@", result);
    return result;    
}

- (NMSimplifiedCursor *)simplifiedCursor
{
    return [[NMSimplifiedCursor alloc] initWithImage:[self image]];
}

+ (NSNumber *)standardArrowPlaceholder
{
    return @-1;
}

+ (NSNumber *)standardBeamPlaceholder
{
    return @-2;
}

+ (NSNumber *)standardBlankPlaceholder
{
    return @-3;
}

@end


/*
 Stores a cursor as a grid of on/off values based on an analysis of the pixels.
 For example:
 ........................ .XX...XX........
 ........................ ...X.X..........
 ........................ ....X...........
 ........................ ....X...........
 ....X................... ....X...........
 ....XX.................. ....X...........
 ....XXX................. ...XXX..........
 ....XXXX................ ....X...........
 ....XXXXX............... ....X...........
 ....XXXXXX.............. ....X...........
 ....XXXXXXX............. ....X...........
 ....XXXXXXXX............ ....X...........
 ....XXXXX............... ...X.X..........
 ....XX.XX............... .XX...XX........
 ....X...XX..............
 ........XX..............
 .........XX.............
 .........XX.............
 ........................
 ........................
 ........................
 ........................
 ........................
 ........................
 */

@implementation NMSimplifiedCursor
@synthesize pixelsPerRow=_pixelsPerRow, numberOfRows=_numberOfRows, data=_data;

typedef struct {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
    unsigned char alpha;
} RGBData;

- (BOOL)validateSize
{
    const NSInteger MIN_SIDE=6;
    const NSInteger MAX_SIDE=72;
    return _pixelsPerRow>=MIN_SIDE&&_numberOfRows>=MIN_SIDE&&_pixelsPerRow<=MAX_SIDE&&_numberOfRows<=MAX_SIDE;
}

/* Init with the output of displayString */
- (id)initWithAsciiArt:(NSString *)asciiArt
{
    self=[super init];
    if (self) {
        NSMutableData *tempData=[NSMutableData dataWithCapacity:[asciiArt length]];
        NSInteger lineLength=-1;
        NSInteger lineCount=0;
        for (__strong NSString *line in [asciiArt componentsSeparatedByString:@"\n"]) {
            line=[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([line length]==0) {
                // skip blank lines
                NMLogFine(@"Skipping blank line",nil);
                continue;
            }
            
            // count lines
            lineCount+=1;
            
            // get initial line length
            if (lineLength<0) {
                lineLength=[line length];
            }
            
            // check line length
            if (lineLength!=[line length]) {
                NMLogWarning(@"Uneven line lengths %li, %li.", lineLength, [line length]);
                return nil;
            }
            
            // convert chars
            const unsigned char CHAR_ON=0xff;
            const unsigned char CHAR_OFF=0;
            for (NSInteger i=0; i<lineLength; i+=1) {
                NSString *const c=[line substringWithRange:NSMakeRange(i, 1)];
                if ([@"." isEqualToString:c]) {
                    [tempData appendBytes:&CHAR_OFF length:1];
                }
                else if ([@"X" isEqualToString:c]) {
                    [tempData appendBytes:&CHAR_ON length:1];
                }
                else {
                    NMLogWarning(@"Unexpected character");
                    return nil;
                }
            }
        }
        _pixelsPerRow=lineLength;
        _numberOfRows=lineCount;
        if (![self validateSize]) {
            NMLogWarning(@"Bad size  %li x %li", _pixelsPerRow, _numberOfRows);
            return nil;
        }
        _data=tempData;
    }
    return self;
}

- (id)initWithImage:(NSImage *)image;
{
    self=[super init];
    if (self)
    {
        // get birmap representation
        NSArray *const representations=[image representations];
        if ([representations count]<1) {
            return nil;
        }
        NSBitmapImageRep *const rep=representations[0];
        
        // check not too big
        _pixelsPerRow=[image size].width;
        _numberOfRows=[image size].height;
        if (![self validateSize]) {
            NMLogFine(@"Cursor size is %@.", NSStringFromSize([image size]));
            return nil;
        }
        
        // check rgb color space
        NSColorSpace *const colorSpace=[rep colorSpace];
        if (!([colorSpace isEqual:[NSColorSpace genericRGBColorSpace]]||[colorSpace isEqual:[NSColorSpace deviceRGBColorSpace]])) {
            NMLogFine(@"Cursor has unexpected color space: %@", colorSpace);
            return nil;
        }
        
        // check not planar
        const BOOL isPlanar=[rep isPlanar];    
        if (isPlanar) {
            NMLogFine(@"Cursor is planar.");
            return nil;
        }
        
        // check other data
        const NSInteger numberOfPlanes=[rep numberOfPlanes];
        const NSInteger samplesPerPixel=[rep samplesPerPixel];
        const NSInteger bytesPerRow=[rep bytesPerRow];
        if (numberOfPlanes!=1||samplesPerPixel!=4) {
            NMLogFine(@"Cursor geometry unexpected: planes %li, spp %li.", numberOfPlanes, samplesPerPixel);
            return nil;
        }        
        
        // the data
        const unsigned char *const fullData=(const unsigned char *)[rep bitmapData];
        _data=[NSMutableData dataWithLength:_numberOfRows*_pixelsPerRow]; // zeroed
        unsigned char *const outputData=[(NSMutableData *)_data mutableBytes];
        
        // print the alpha values
        NSInteger pos=0, white=0, black=0;
        for (NSInteger row=0; row<_numberOfRows; row++) {
            RGBData *rowData=(RGBData *)(fullData+bytesPerRow*row);
            for (NSInteger pixel=0; pixel<_pixelsPerRow; pixel++) {
                RGBData pixelData=rowData[pixel];  
                const unsigned char ALPHA_THRESHHOLD=175;
                if (pixelData.alpha>=ALPHA_THRESHHOLD) {
                    
                    // is it white or black-ish?
                    CGFloat temp=pixelData.red;
                    temp+=pixelData.green;
                    temp+=pixelData.blue;
                    const CGFloat brightness=temp/(255*3);
                    if (brightness>0.5) {
                        white++;
                        outputData[pos]='w';
                    }
                    else {
                        black++;
                        outputData[pos]='b';   
                    }
                }
                pos++;
            }                           
        }
        
        // blast the white or black
        unsigned char winner=black>white?'b':'w';
        for (NSInteger i=0; i<_numberOfRows*_pixelsPerRow; i++) {
            outputData[i]=outputData[i]==winner?0xff:0;
        }
        
    }
    return self;
}

/*
 Return an ASCII-art string representing the data
 */
- (NSString *)asciiArt
{
    NSMutableString *const result=[NSMutableString stringWithCapacity:(_pixelsPerRow+1)*_numberOfRows];
    const unsigned char *values=[self.data bytes];
    NSInteger pos=0;
    for (NSInteger row=0; row<self.numberOfRows; row++) {
        for (NSInteger pix=0; pix<self.pixelsPerRow; pix++) {
            [result appendString:values[pos]==0?@".":@"X"];
            pos++;
        }
        [result appendString:@"\n"];
    }
    return result;
}


static NSInteger _matchRowB(const unsigned char *rowData, NSInteger len, NSInteger d)
{
    NSInteger result=-1;
    NSInteger first=-1;
    
    // count number of 'on' pixels
    NSInteger on=0;
    for (NSInteger i=0; i<len; i++) {
        if (rowData[i]) {
            if (first<0) {
                first=i;
            }
            on+=1;
        }
    }
    
    if (on==d) {
        BOOL allMatch=YES;
        for (int i=0; i<d; i+=1) {
            if (rowData[first+i]!=0xff) {
                allMatch=NO;
            }
        }
        if (allMatch) {
            result=first;
        }
    }
    return result;
}

// d=separation
// t=thickness
// f=filledin
static NSInteger _matchRowA(const unsigned char *rowData, NSInteger len, NSInteger d, NSInteger t, BOOL f)
{
    NSInteger result=-1;
    NSInteger first=-1;
    
    // count number of 'on' pixels
    NSInteger on=0;
    for (NSInteger i=0; i<len; i++) {
        if (rowData[i]) {
            if (first<0) {
                first=i;
            }
            on+=1;
        }
    }
    
    if (on==2*t+(f?d:0)&&first<len-(d+2*t)+1) {
        BOOL outerMatch=YES;
        for (int i=0; i<t; i+=1) {
            if (rowData[first+i]!=0xff||rowData[first+d+t+i]!=0xff) {
                outerMatch=NO;
            }
        }
        
        if (outerMatch) {
            BOOL allMatch=YES;
            for (int i=0; i<d; i+=1) {
                if (rowData[first+i+t]!=(f?0xff:0)) {
                    allMatch=NO;
                }
            }
            if (allMatch) {
                result=first+t;
            }
        }
    }

    return result;
}

/*
 Decide whether this looks like an Ibeam cursor
 Look for these parts:
 A1...X.X....
 B1....X.....
   ....X.....
 and
 ....X.....
 ....X.....
 ...X.X....
 
 or
 
 A2...X..X...
 B2....XX....
   ....XX....
 and
   ....XX....
   ....XX.... 
   ...X..X...
 
 or 
 A3...XX..XX..
 B3.....XX....
   .....XX....
 and
   .....XX....
   .....XX....
   ...XX..XX..

 
 OR same but with gap at top filled
 */


- (BOOL)isBeam
{
    const unsigned char *values=[_data bytes];
    // look for a row A followed by two row B's, in the top half
    
    for (NSInteger fill=0; fill<=1; fill++) {
        for (NSInteger d=1; d<=2; d+=1) {
            for (NSInteger t=1; t<=2; t+=1) {
                for (NSInteger i=0; i<_numberOfRows/2; i++) {
                    const NSInteger rowAPosition=_matchRowA(values+i*_pixelsPerRow, _pixelsPerRow, d, t, fill==1);
                    if (rowAPosition>0)
                    {
                        if (rowAPosition==_matchRowB(values+(i+1)*_pixelsPerRow, _pixelsPerRow, d) &&
                            rowAPosition==_matchRowB(values+(i+2)*_pixelsPerRow, _pixelsPerRow, d))
                        {
                            // look for the same thing inverted in the bottom half
                            for (NSInteger j=_numberOfRows-1; j>(_numberOfRows-1)-(_numberOfRows/2); j--) {
                                if (rowAPosition==_matchRowA(values+j*_pixelsPerRow, _pixelsPerRow, d, t, fill==1)&&
                                    rowAPosition==_matchRowB(values+(j-1)*_pixelsPerRow, _pixelsPerRow, d) &&
                                    rowAPosition==_matchRowB(values+(j-2)*_pixelsPerRow, _pixelsPerRow, d))
                                {
                                    return YES;
                                }
                            }
                            break;
                        }
                    }
                }
            }
        }
    }
    
    return NO;
}

/*
 Look for
 ..X.......
 ..XX......
 ..XXX.....
 ..XXXX....
 ..XXXXX...
 in the top half
 
 or 
 ..XX......
 ..XX......
 ..XXXX....
 ..XXXX....
 ..XXXXX...
 */
- (BOOL)isArrow
{
    const unsigned char *values=[_data bytes];
    
    // x-offset of arrow point
    NSInteger pointPosition=-1;
    NSInteger lookingFor=0;
    
    const NSInteger NUM_PATTERNS=3;
    NSInteger patterns[NUM_PATTERNS][5]={{1,2,3,4,5},{2,2,4,4,5},{2,2,3,5,5}};
    
    // for each line
    for (NSInteger pattern=0; pattern<NUM_PATTERNS; pattern+=1) {
        for (NSInteger i=0; i<_numberOfRows/2; i++) {
            NSInteger matchPosition=_matchRowB(values+i*_pixelsPerRow, _pixelsPerRow, patterns[pattern][lookingFor]);
            if ((matchPosition<0)||(pointPosition>=0&&pointPosition!=matchPosition)) {
                // no match
                pointPosition=-1;
                lookingFor=0;
            }
            else {
                if (pointPosition<0) {
                    pointPosition=matchPosition;
                }
                if(4==lookingFor) {
                    return YES;
                }
                lookingFor++;
            }
        }
    }

    
    return NO;
}

- (BOOL)isBlank
{
    const unsigned char *values=[_data bytes];
    for (int i=0; i<[_data length]; i++)
    {
        if (values[i]!=0) {
            return NO;
        }
    }
    return YES;
}

@end