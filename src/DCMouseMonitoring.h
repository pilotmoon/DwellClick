// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
@class NMPoint;

@protocol DCMouseMonitoringDelegate
- (void)mouseDidMove;
- (void)mouseDidDwell;
- (void)mouseDidDwellIgnore;
- (void)mouseButtonWasPressed;
- (void)mouseButtonWasReleased;
@end

@protocol DCMouseMonitoring
@property (assign) id<DCMouseMonitoringDelegate> delegate;
@property NSTimeInterval dwellTime;
@property CGFloat dwellRadius;
- (void)startDwellDetect;
- (void)stopDwellDetect;
@property CGFloat moveRadius;
- (void)startMoveDetectWithLocation:(NMPoint *)point;
- (void)startMoveDetect;
- (void)stopMoveDetect;
@end
