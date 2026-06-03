// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#include <objc/runtime.h>
#import "NMStateMachine.h"
#import "NMState.h"
#import "NSMutableDictionary+NMSafe.h"

static void _dynamicEvent(id self, SEL sel)
{
    [self handleEventWithName:NSStringFromSelector(sel)];
}

@implementation NMStateMachine

@synthesize currentState=_currentState, states=_states, eventNames=_eventNames, dependencies=_dependencies;

- (id)initWithInitialState:(NMState *)state
{
	if (!(self=[super init])) {
		return nil;
	}
	
	self.currentState = state;	
	self.states = [state reachableStates];

	// build the set of all event names
	self.eventNames = [NSMutableSet set];
    self.dependencies = [NSMutableDictionary dictionary];
	for(NMState *s in self.states) {
		[(NSMutableSet *)self.eventNames unionSet:s.eventNames];
        for (id key in s.dependencies) {
            [[(NSMutableDictionary *)self.dependencies storageSetForKey:key] unionSet:(s.dependencies)[key]];
        }
	}
	
	// add methods for event names
	for(NSString *name in self.eventNames) {
		class_addMethod([self class], NSSelectorFromString(name), (IMP) _dynamicEvent, "v@:");		
	}

	return self;
}

- (void)handleEventWithName:(NSString *)aEventName
{
	self.currentState=[self.currentState doTransition:aEventName];
}

@end
