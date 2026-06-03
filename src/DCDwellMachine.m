// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "DCDwellMachine.h"
#import "NMKit/NMStateMachine.h"
#import "NMKit/NMState.h"

@implementation DCDwellMachine
@synthesize clickController, tap, monitor, stateMachine;

#pragma mark Initialization

- (void)setUpStateMachine
{
	offState = [[NMState alloc] initWithName:@"Off"
											   target:tap
											   action:@selector(stop)];
	NMState *moveState = [[NMState alloc] initWithName:@"MoveDetect"
												target:monitor
												action:@selector(startMoveDetect)];
	NMState *dwellState = [[NMState alloc] initWithName:@"DwellDetect"
												 target:monitor
												 action:@selector(startDwellDetect)];
	NMState *buttonState = [[NMState alloc] initWithName:@"ButtonDown"];
	
	[offState addTransition:@"start"
				  nextState:moveState
					 target:tap
					 action:@selector(start)];
	
	[moveState addTransition:@"performNow"
					nextState:moveState
					   target:clickController
					   action:@selector(reallyPerformNextAction)];
	
	[moveState addTransition:@"performInstant"
					nextState:moveState
					   target:clickController
					   action:@selector(reallyPerformNextAction)];

	[moveState addTransition:@"performSilent"
				   nextState:moveState];
	
	[moveState addTransition:@"mouseDidMove"
				   nextState:dwellState];
	
	[moveState addTransition:@"mouseButtonWasPressed"
				   nextState:buttonState
					  target:monitor
					  action:@selector(stopMoveDetect)];
	
	[moveState addTransition:@"stop"
				   nextState:offState];
	
	[dwellState addTransition:@"mouseDidDwell"
					nextState:moveState
					   target:clickController
					   action:@selector(performNextAction)];
	
	[dwellState addTransition:@"mouseDidDwellIgnore"
					nextState:moveState];
	
	[dwellState addTransition:@"mouseButtonWasPressed"
					nextState:buttonState
					   target:monitor
					   action:@selector(stopDwellDetect)];
	
	[dwellState addTransition:@"performInstant"
				   nextState:moveState
					  target:clickController
					  action:@selector(reallyPerformNextAction)];
	
	[dwellState addTransition:@"stop"
					nextState:offState];
	
	[buttonState addTransition:@"mouseButtonWasReleased"
					 nextState:moveState];
	
	[buttonState addTransition:@"stop"
					 nextState:offState];
	
	stateMachine = [[NMStateMachine alloc] initWithInitialState:offState];
}

- (id)initWithTap:(id<DCActivation>)aTap
		  monitor:(id<DCMouseMonitoring>)aMonitor
  clickController:(id<DCClickControl>)aClickController;
{
	if (!(self=[super init])) {
		return nil;	
	}
	
	[self setTap:aTap];
	[self setMonitor:aMonitor];
	[self setClickController:aClickController];
	[self setUpStateMachine];
	
	return self;
}

#pragma mark Clever forwarding method

- (id)forwardingTargetForSelector:(SEL)sel
{
	return stateMachine;
}

#pragma mark Active setting accessors

- (void)setActive:(BOOL)state
{
	state?[self start]:[self stop];
}

- (BOOL)isActive
{
	return !(stateMachine.currentState==offState);
}

+ (NSSet *)keyPathsForValuesAffectingActive
{
	return [NSSet setWithObject:@"stateMachine.currentState"];
}

@end

