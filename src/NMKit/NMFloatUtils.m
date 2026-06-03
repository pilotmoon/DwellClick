// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#include "NMFloatUtils.h"


CGFloat NMFloatLimit(CGFloat f, CGFloat min, CGFloat max)
{
    if (f<min) return min;
    if (f>max) return max;
    return f;
}

CGFloat NMFloatRandomSigned(void)
{
    return (((CGFloat)2.0)*random())/INT_MAX-1;
}

CGFloat NMFloatRandomUnsigned(void)
{
    return (((CGFloat)1.0)*random())/INT_MAX;
}

CGFloat NMFloatRandomRange(CGFloat a, CGFloat b)
{
    return a+NMFloatRandomUnsigned()*(b-a);
}

NSComparisonResult NMCompareFloats(CGFloat f1, CGFloat f2)
{
    if (f2>f1) {
        return NSOrderedAscending;
    }
    else if (f2<f1) {
        return NSOrderedDescending;
    }
    else {
        return NSOrderedSame;
    }
}