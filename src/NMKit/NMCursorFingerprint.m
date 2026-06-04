// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMCursorFingerprint.h"
#import "NMCoreUtils.h"
#import "NMLog.h"
#import "NMSuperFastHash.h"

typedef struct {
    unsigned char alpha;
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} RGBA;

static NSString *const _prefix=@":";
static NSString *const _suffixOutline=@"0:";
static NSString *const _suffixFlat=@"1:";
static const NSInteger maxSide=80, minSide=4;

static NSNumber *_superFastHashBitmap(NSBitmapImageRep *bitmap)
{
    const char * const data=(const char *)[bitmap bitmapData];
    const NSInteger bytesInImage=[bitmap bytesPerPlane]*[bitmap numberOfPlanes];
    const NSInteger maxBytes=maxSide*maxSide*4;
    const uint32_t bytesToCount=(uint32_t)(bytesInImage>maxBytes?maxBytes:bytesInImage);
    return @(NMSuperFastHash(data, bytesToCount));
}

static NSData *_dataWithTrimmedBase64String(NSString *string)
{
    NSMutableString *padded=[string mutableCopy];
    while ([padded length]%4!=0) {
        [padded appendString:@"="];
    }
    return [[NSData alloc] initWithBase64EncodedString:padded options:0];
}

static NSString *_trimmedBase64String(NSData *data)
{
    NSString *result=[data base64EncodedStringWithOptions:0];
    while ([result hasSuffix:@"="]) {
        result=[result substringToIndex:[result length]-1];
    }
    return result;
}

static void _shrink(UInt8 **first, UInt8 **last, const size_t n)
{
    BOOL (^blank)(const UInt8 *) = ^BOOL(const UInt8 *start) {
        for (const UInt8 *p=start; p<start+n; p++) {
            if (*p) return NO;
        }
        return YES;
    };
    while (*first<*last&&blank(*first)) {
        *first+=n;
    }
    while (*last>*first&&blank(*last-n)) {
        *last-=n;
    }
}

static void _transpose(const UInt8 *const inbuf, UInt8 *outbuf, const size_t n, const size_t m)
{
    for (int i=0; i<n; i++) {
        const UInt8 *p=inbuf+i;
        for (int j=0; j<m; j++) {
            *(outbuf++)=*p;
            p+=n;
        }
    }
}

static NSData *_pack(const UInt8 *buf, const size_t width, const size_t height)
{
    const size_t pixels=width*height;
    NSMutableData *const packedData=[NSMutableData dataWithLength:2+(pixels+7)/8];
    UInt8 *p=[packedData mutableBytes];
    *p++=width;
    *p++=height;
    int bit=0;
    for (int i=0; i<pixels; i+=1) {
        *p^=buf[i]<<bit;
        bit=(bit+1)%8;
        if (bit==0) {
            p+=1;
        }
    }
    return [packedData copy];
}

static NSData *_fingerprintDataForBitmap(NSBitmapImageRep *bitmap, BOOL flatten)
{
    static NSSet *_allowedColorSpace=nil;
    if (!_allowedColorSpace) {
         _allowedColorSpace=[NSSet setWithArray:@[[NSColorSpace genericRGBColorSpace],[NSColorSpace deviceRGBColorSpace]]];
    }

    const size_t width=bitmap.pixelsWide, height=bitmap.pixelsHigh;
    const RGBA *const input=(RGBA *)[bitmap bitmapData];

    if (![_allowedColorSpace containsObject:bitmap.colorSpace] ||
        width<minSide || width>maxSide || height<minSide || height>maxSide ||
        bitmap.planar || bitmap.numberOfPlanes !=1 ||
        bitmap.bitsPerSample !=8 || bitmap.samplesPerPixel !=4 ||
        bitmap.bytesPerRow != width * 4) {
        NMLogInfo(@"Cursor bitmap properties: size %i x %i, space %@, planar %i, planes %li, bps %li, spp %li, bpr %li",
                  (int)width, (int)height, bitmap.colorSpace, bitmap.planar, bitmap.numberOfPlanes,
                  bitmap.bitsPerSample, bitmap.samplesPerPixel, bitmap.bytesPerRow);
        return nil;
    }

    const size_t length=height*width;
    UInt8 *s=calloc(length, sizeof(UInt8));
    UInt8 *t=calloc(length, sizeof(UInt8));

    UInt8 f=0;
    UInt8 *q=s;
    for (const RGBA *p=input; p<input+length; p++, q++) {
        if (p->alpha>175) {
            if (flatten) {
                *q=1;
            }
            else {
                const UInt8 x=p->red+p->green+p->blue>((255*3)/2)?'w':'b';
                if (!f) f=x;
                *q=(x==f)?1:0;
            }
        }
    }

    size_t n=width, m=height;
    int loop=2;
    while (n&&loop--)
    {
        UInt8 *first=s, *last=first+n*m;
        _shrink(&first, &last, n);
        m=(last-first)/n;

        _transpose(first, t, n, m);

        UInt8 *ss=s;
        s=t;
        t=ss;
        size_t nn=n;
        n=m;
        m=nn;
    }
    NSData *result=_pack(s, n, m);

    free(s);
    free(t);
    return result;
}

static NSString *_asciiArt(const UInt8 *buf)
{
    const UInt8 width=*buf++;
    const UInt8 height=*buf++;
    NSMutableString *const art=[NSMutableString string];
    NSUInteger bit=0, pixel=0;
    while (pixel++<width*height) {
        [art appendString:(*buf&(1<<bit))?@"X":@"."];
        if (!(bit=(bit+1)%8)) buf++;
        if (!(pixel%width)) [art appendString:@"\n"];
    }
    return art;
}

@interface NMCursorFingerprint()
@property NSData *pixelsOutline;
@property NSData *pixelsFlat;
@end

@implementation NMCursorFingerprint

+ (NMCursorFingerprint *)fingerprintWithCursor:(NSCursor *)cursor
{
    return [[NMCursorFingerprint alloc] initWithCursor:cursor];
}

- (id)initWithOutline:(NSData *)pixelsOutline flat:(NSData *)pixelsFlat
{
    if (!([pixelsFlat isKindOfClass:[NSData class]]||[pixelsOutline isKindOfClass:[NSData class]])) {
        return nil;
    }
    self=[super init];
    if (self) {
        self.pixelsOutline=pixelsOutline;
        self.pixelsFlat=pixelsFlat;
    }
    return self;
}

- (id)initWithString:(NSString *)string
{
    const BOOL isOutline=[string hasSuffix:_suffixOutline];
    const BOOL isFlat=[string hasSuffix:_suffixFlat];
    if (![string hasPrefix:_prefix] || (!isOutline && !isFlat)) {
        return nil;
    }

    const NSRange range=NSMakeRange([_prefix length], [string length]-[_prefix length]-[_suffixOutline length]);
    NSData *const data=_dataWithTrimmedBase64String([string substringWithRange:range]);
    const UInt8 *const buf=[data bytes];
    const NSUInteger len=[data length];

    if (len<2) {
        return nil;
    }
    const NSUInteger width=buf[0];
    const NSUInteger height=buf[1];

    if ((width*height+7)/8!=len-2) {
        return nil;
    }

    if (isOutline) {
        return [self initWithOutline:data flat:nil];
    }
    else if (isFlat) {
        return [self initWithOutline:nil flat:data];
    }
    return nil;
}

- (id)initWithCursor:(NSCursor *)cursor
{
    static NSMutableDictionary<NSNumber *, NMCursorFingerprint *> *lookup=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lookup=[NSMutableDictionary dictionary];
    });

    NSBitmapImageRep *const bitmap=(NSBitmapImageRep *)[[[cursor image] representations] safeFirstObject];
    if (![bitmap isKindOfClass:[NSBitmapImageRep class]]) {
        return nil;
    }

    NSNumber *const sfh=_superFastHashBitmap(bitmap);
    NMCursorFingerprint *const cached=lookup[sfh];
    if (cached) {
        return cached;
    }

    NMCursorFingerprint *fp=[self initWithOutline:_fingerprintDataForBitmap(bitmap, NO)
                                             flat:_fingerprintDataForBitmap(bitmap, YES)];
    if (fp) {
        lookup[sfh]=fp;
    }
    return fp;
}

- (NSString *)standardString
{
    NSData *const data=self.pixelsFlat?self.pixelsFlat:self.pixelsOutline;
    return [NSString stringWithFormat:@"%@%@%@", _prefix, _trimmedBase64String(data), self.pixelsFlat?_suffixFlat:_suffixOutline];
}

- (NSString *)asciiArt
{
    NSData *fpData=self.pixelsFlat?self.pixelsFlat:self.pixelsOutline;
    return _asciiArt([fpData bytes]);
}

static BOOL _pixelDiff(NSData *a, NSData *b, CGFloat tolerance)
{
    const UInt8 *abuf=[a bytes];
    const UInt8 *bbuf=[b bytes];
    NSSize asize=NSMakeSize(abuf[0], abuf[1]);
    NSSize bsize=NSMakeSize(bbuf[0], bbuf[1]);
    if (!NSEqualSizes(asize, bsize)) {
        return NO;
    }
    NSInteger diff=0, tota=0, totb=0;
    NSUInteger bit=0, pixel=0;
    abuf+=2;
    bbuf+=2;
    while (pixel++<asize.width*asize.height) {
        BOOL aval=!!(*abuf&(1<<bit));
        BOOL bval=!!(*bbuf&(1<<bit));
        if (aval) tota+=1;
        if (bval) totb+=1;
        if (aval!=bval) diff+=1;
        if (!(bit=(bit+1)%8)) {
            abuf++;
            bbuf++;
        }
    }

    NSInteger tot=MAX(tota,totb);
    NSInteger thresh=MAX(tolerance*tot,4);
    return diff<=thresh;
}

static BOOL _cleverMatch(NSData *a, NSData *b)
{
    return a&&b&&_pixelDiff(a, b, 0.25);
}

- (BOOL)fuzzyMatchFingerprint:(NMCursorFingerprint *)other
{
    if ([self.pixelsFlat isEqualToData:other.pixelsFlat]) {
        return YES;
    }
    if ([self.pixelsOutline isEqualToData:other.pixelsOutline]) {
        return YES;
    }
    if (_cleverMatch(self.pixelsFlat, other.pixelsFlat)) {
        return YES;
    }
    if (_cleverMatch(self.pixelsOutline, other.pixelsOutline)) {
        return YES;
    }
    return NO;
}

- (BOOL)isEqualToFingerprint:(NMCursorFingerprint *)other
{
    return ((self.pixelsFlat==other.pixelsFlat||[self.pixelsFlat isEqualToData:other.pixelsFlat]) &&
            (self.pixelsOutline==other.pixelsOutline||[self.pixelsOutline isEqualToData:other.pixelsOutline]));
}

- (BOOL)isEqual:(id)object
{
    if (self==object) {
        return YES;
    }
    if (![object isKindOfClass:[NMCursorFingerprint class]]) {
        return NO;
    }
    return [self isEqualToFingerprint:object];
}

- (NSUInteger)hash
{
    return self.pixelsOutline.hash|self.pixelsFlat.hash;
}

- (NSString *)description
{
    return [self standardString];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    return self;
}

@end
