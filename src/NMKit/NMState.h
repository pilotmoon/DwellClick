// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

@interface NMState : NSObject {
	__unsafe_unretained id _target;  // target for entry action
	SEL _action; // entry action

    __unsafe_unretained id _exitTarget;  // target for exit action
	SEL _exitAction; // exit action
    
    NSString *_name;
	NSMutableDictionary *_transitions;
}
- (NSString *)name;

- (id)initWithName:(NSString *)aName
            target:(id)aTarget
			action:(SEL)aAction
        exitTarget:(id)aTarget
        exitAction:(SEL)aAction;

- (id)initWithName:(NSString *)aName
			target:(id)aTarget
			action:(SEL)aAction;

- (id)initWithName:(NSString *)aName;

- (void)addTransition:(NSString *)aEventName
			nextState:(NMState *)aNextState
			   target:(id)aTarget
			   action:(SEL)aAction;

- (void)addTransition:(NSString *)aEventName
			nextState:(NMState *)aNextState;

- (NMState *)doTransition:(NSString *)aEventName;

- (NSSet *)eventNames;
- (NSSet *)nextStates;
- (NSSet *)reachableStates;
- (NSDictionary *)dependencies;

@end
