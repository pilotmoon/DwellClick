// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMState.h"
#import "NSMutableDictionary+NMSafe.h"

// private struct-like class to hold transitions
@interface Transition : NSObject
{
@public
	__unsafe_unretained NMState *nextState;
    __unsafe_unretained id target;
	SEL action;
}
@end

@implementation Transition
@end

@interface NMState ()
@property (copy) NSString *name;
@property (unsafe_unretained) id target;
@property SEL action;
@property (unsafe_unretained) id exitTarget;
@property SEL exitAction;
@property (retain) NSMutableDictionary *transitions;
@end

@implementation NMState
@synthesize name=_name, target=_target, action=_action, exitTarget=_exitTarget, exitAction=_exitAction, transitions=_transitions;

#pragma mark Setting up

- (id)initWithName:(NSString *)aName
            target:(id)aTarget
			action:(SEL)aAction
        exitTarget:(id)aExitTarget
        exitAction:(SEL)aExitAction
{
    if (!(self=[super init])) {
		return nil;
	}
	
	self.target = aTarget;
	self.action = aAction;
    self.exitTarget = aExitTarget;
    self.exitAction = aExitAction;
	self.name = aName;
	self.transitions = [NSMutableDictionary dictionary];
	return self;
}

- (id)initWithName:(NSString *)aName
			target:(id)aTarget
			action:(SEL)aAction
{
    return [self initWithName:aName target:aTarget action:aAction exitTarget:nil exitAction:nil];
}

- (id)initWithName:(NSString *)aName
{
	return [self initWithName:aName target:nil action:nil exitTarget:nil exitAction:nil];
}

- (id)init
{
	return [self initWithName:nil target:nil action:nil exitTarget:nil exitAction:nil];
}

#pragma mark Transitions

- (void)addTransition:(NSString *)aEventName
			nextState:(NMState *)aNextState
			   target:(id)aTarget
			   action:(SEL)aAction
{
	Transition *t = [[Transition alloc] init];
	t->nextState=aNextState;
	t->target=aTarget;
	t->action=aAction;
	(self.transitions)[aEventName] = t;
}

- (void)addTransition:(NSString *)aEventName
			nextState:(NMState *)aNextState
{
	[self addTransition:aEventName
			  nextState:aNextState
				 target:nil
				 action:nil];
}

- (NMState *)doTransition:(NSString *)aEventName
{
	Transition *t=(self.transitions)[aEventName];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	if (t) {
        NMLogTiny(@"'%@' + %@ --> '%@'", self.name, aEventName, t->nextState.name);
        
        if (self.exitTarget) NMLogTiny(@" exit [%@ %@]", [self.exitTarget class], NSStringFromSelector(self.exitAction));
        [self.exitTarget performSelector:self.exitAction];
        
        if (t->target) NMLogTiny(@"trans [%@ %@]", [t->target class], NSStringFromSelector(t->action));
		[t->target performSelector:t->action];

        if (t->nextState.target) NMLogTiny(@"enter [%@ %@]", [t->nextState.target class], NSStringFromSelector(t->nextState.action));
		[t->nextState.target performSelector:t->nextState.action];
        
		return t->nextState;
	}
	else {
		// no transition for event
		return self;
	}
#pragma clang diagnostic pop                    
}

#pragma mark NSObject methods

- (NSString *)description
{
	return [self name];
}

#pragma mark Introspection...

// set of event names this state responds to
- (NSSet *)eventNames
{
	return [NSSet setWithArray:[self.transitions allKeys]];
}

// set of all objects and selectors this state and its transitions can call
- (NSMutableDictionary *)dependencies
{
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    if (_target&&_action&&[[_target description] isKindOfClass:[NSString class]]) {
        [[result storageSetForKey:[_target description]] addObject:NSStringFromSelector(_action)];
    }
    if (_exitTarget&&_exitAction&&[[_exitTarget description] isKindOfClass:[NSString class]]) {
        [[result storageSetForKey:[_exitTarget description]] addObject:NSStringFromSelector(_exitAction)];
    }
    for (Transition *t in [self.transitions allValues]) {
        if (t->target&&t->action&&[[t->target description] isKindOfClass:[NSString class]]) {
            [[result storageSetForKey:[t->target description]] addObject:NSStringFromSelector(t->action)];
        }
    }    
    return result;
}

// set of states immediately reachable from this state
- (NSSet *)nextStates
{
	NSMutableSet *result = [NSMutableSet set];
	for(Transition *t in [self.transitions allValues]) {
		[result addObject:t->nextState];
	}
	return result;
}

// walk the state graph to find all states reachable from this one
- (NSSet *)reachableStates;
{
	NSMutableSet *result = [NSMutableSet set];
	NSMutableArray *stack = [NSMutableArray arrayWithObject:self];
	
	while ([stack count] > 0) {
		// pop top item
		NMState *item = [stack lastObject];
		[stack removeLastObject];
		
		// if in set, next
		if (![result containsObject:item]) {
			// else add to set and add next states to stack
			[result addObject:item];
			[stack addObjectsFromArray:[[item nextStates] allObjects]];
		}
	}
	return result;
}


@end
