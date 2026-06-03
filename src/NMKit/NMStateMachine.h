// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>
@class NMState;

@interface NMStateMachine : NSObject {
	__unsafe_unretained NMState *_currentState;
    NSSet *_states;
	NSSet *_eventNames;
    NSDictionary *_dependencies;
}
@property (unsafe_unretained) NMState *currentState;
@property (retain) NSSet *states;
@property (retain) NSSet *eventNames;
@property (retain) NSDictionary *dependencies;

- (id)initWithInitialState:(NMState *)state;

- (void)handleEventWithName:(NSString *)aEventName;

@end
