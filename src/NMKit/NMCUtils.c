// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#include "NMCUtils.h"

void *NM_memset(void *_p, int v, unsigned long count)
{
    unsigned char *p = _p;
    while(count-- > 0) *p++ = v;
    return _p;
}
