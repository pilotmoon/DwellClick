// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
#import "DCActivation.h"
#import "DCMouseMonitoring.h"
#import "DCClickControl.h"
#import "NMKit/NMStateMachine.h"
#import "NMKit/NMState.h"

@interface DCDwellMachine : NSObject {
	NMStateMachine *stateMachine;
	NMState *offState;
	id<DCClickControl> __strong clickController;
	id<DCActivation> __strong tap;
	id<DCMouseMonitoring> __strong monitor;
}
@property (strong) id<DCClickControl> clickController;
@property (strong) id<DCActivation> tap;
@property (strong) id<DCMouseMonitoring> monitor;
@property (readonly) NMStateMachine *stateMachine;

- (id)initWithTap:(id<DCActivation>)aTap
		  monitor:(id<DCMouseMonitoring>)aMonitor
  clickController:(id<DCClickControl>)aClickController;

@end

@interface DCDwellMachine (Actions) <DCMouseMonitoringDelegate, DCActivation>
- (void)performNow; // now or after dwell is detected if dwell detecting
- (void)performInstant; // really right now
- (void)performSilent; // change state but don't perform action
@end
