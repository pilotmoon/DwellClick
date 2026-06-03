// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMPoint.h"
#import "NMUIElement.h"
#import "NMUIElementHelper.h"
#import "NMBlockUtils.h"
#import "NMCoreUtils.h"

static NMUIElementHelper *_helper;

NSInteger _retains;

@implementation NMUIElement
@synthesize elementRef=_elementRef, role=_role, attributeNames=_attributeNames;

+ (void)initialize
{
	if (self == [NMUIElement class]) // standard check to prevent multiple runs
    {
		_helper=[[NMUIElementHelper alloc] init];
    }
}

+ (NMUIElement *)elementAtLocation:(NMPoint *)point
						   timeout:(NSTimeInterval)timeout
{
    NMUIElement *result=nil;
    AXUIElementRef ref=[_helper elementAtUnflippedLocation:[point nsPoint] timeout:timeout];
    if (ref) {
        result=[[NMUIElement alloc] initWithElement:ref];
        CFRelease(ref);
    }
    return result;
}

+ (AXError)lastError
{
	return [_helper lastError];
}

static NSSet *_attributeNamesForElement(AXUIElementRef ref)
{
    NSMutableSet *result=[NSMutableSet set];
    
    @try {
        CFArrayRef array=NULL;
        const AXError err=AXUIElementCopyAttributeNames(ref, &array);
        if (err==kAXErrorSuccess&&array) {
            [result addObjectsFromArray:CFBridgingRelease(array)];
        }
    }
    @catch (NSException *exception) {
        NMLogError(@"Caught exception in _attributeNamesForElement: %@", exception);
    }
    return result;
}

- (id)initWithElement:(AXUIElementRef)element knownParents:(NSArray *)parents attributeNames:(NSSet *)attributeNames
{
    self=[super init];
    if (self) {
        if(!element) {
            return nil;   
        }        
        _elementRef=element;
        _attributeNames=attributeNames;        
        _parentElements=[parents copy];
        _role=[self stringAttributeWithName:kAXRoleAttribute];
        CFRetain(element);
    }
    return self;
}

- (void)dealloc
{
    if (_elementRef) {
        //NMLogFine(@"--- Releasing element ref (%lu  - %li) %@ : %@ '%@'", CFGetRetainCount(_elementRef), --_retains, _elementRef, self.role, self.title); 
        CFRelease(_elementRef);   
    }
}

- (id)initWithElement:(AXUIElementRef)element
{
    return [self initWithElement:element knownParents:nil attributeNames:_attributeNamesForElement(element)];
}

- (id)genericAttributeWithName:(CFStringRef)attributeName
{
    id result=nil;
    if ([self.attributeNames containsObject:(__bridge NSString *)attributeName]) {
        CFTypeRef ref=NULL;        
        AXUIElementCopyAttributeValue(_elementRef, attributeName, &ref);
        result=CFBridgingRelease(ref);
    }
    return result;
}

static id _enforceClass(id var, Class class)
{
    return [var isKindOfClass:class]?var:nil;
}

- (NSString *)stringAttributeWithName:(CFStringRef)attributeName
{
   return _enforceClass([self genericAttributeWithName:attributeName], [NSString class]);
}

- (NSNumber *)numberAttributeWithName:(CFStringRef)attributeName
{
    return _enforceClass([self genericAttributeWithName:attributeName], [NSNumber class]);
}

- (NSArray *)arrayAttributeWithName:(CFStringRef)attributeName
{
    return _enforceClass([self genericAttributeWithName:attributeName], [NSArray class]);
}

- (BOOL)boolAttributeWithName:(CFStringRef)attributeName
{
    return [[self numberAttributeWithName:attributeName] boolValue];
}

- (NMUIElement *)elementAttributeWithName:(CFStringRef)attributeName
{
    NMUIElement *result=nil;
    if ([self.attributeNames containsObject:(__bridge NSString *)attributeName]) {
        AXUIElementRef element=NULL;
        AXUIElementCopyAttributeValue(_elementRef, attributeName, (CFTypeRef *)&element);
        if (element) {
            result=[[NMUIElement alloc] initWithElement:element];
            CFRelease(element);
        }
    }
    return result;
}

- (NSArray *)actionNames
{
    CFArrayRef array=NULL;
	AXUIElementCopyActionNames(_elementRef, &array);	
    return CFBridgingRelease(array);
}

- (void)performAction:(NSString *)name
{
	AXUIElementPerformAction(_elementRef, (__bridge CFStringRef)name);
}

/*
 We generate the array of parents and store it. We also store the parent arrays
 in all the parents, while we are at it. Therefore this is only run once for
 any element and all its parents.
 */
- (NSArray *)parents
{
    if (_parentElements) {
        // we already generated the list
        NMLogTiny(@"Returning cached parent list");
        return _parentElements;
    }
    else {
        NMLogTiny(@"Generating parent list");
        
        // limit number of  parents in case of buggy apps with infinite parentage, such as OpenOffice.org
        const NSInteger MAX_PARENTS=32;

        // get array of parent element refs not including self
        NSMutableArray *parentRefs=[NSMutableArray array];
        NSMutableArray *parentAttributeNames=[NSMutableArray array];

        // walk up the parent chain
        AXUIElementRef lastRef=self.elementRef;
        NSSet *lastAttributeNames=self.attributeNames;
        NSInteger parentCount=0;
        while (parentCount<MAX_PARENTS) {
            AXUIElementRef newRef=nil;
            if ([lastAttributeNames containsObject:(__bridge NSString *)kAXParentAttribute]) {
                AXUIElementCopyAttributeValue(lastRef, kAXParentAttribute, (CFTypeRef *)&newRef);
            }
            if (newRef) {
                [parentRefs addObject:CFBridgingRelease(newRef)];                     
                lastRef=newRef;
                lastAttributeNames=_attributeNamesForElement(newRef);
                [parentAttributeNames addObject:lastAttributeNames];
                parentCount+=1;
            }
            else {
                break;
            }
        }
        if (parentCount==MAX_PARENTS) {
            NMLogWarning(@"Parent limit of %li reached.", MAX_PARENTS);
        }
        
        // now back down the list instantiating elements
        NSMutableArray *partialParents=[NSMutableArray arrayWithCapacity:[parentRefs count]];
        [parentRefs enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id reverseRef, NSUInteger idx, BOOL *stop) {
            NMUIElement *const element=[[NMUIElement alloc] initWithElement:(AXUIElementRef)reverseRef
                                                               knownParents:partialParents
                                                             attributeNames:parentAttributeNames[idx]];
            if (element) {
                [partialParents insertObject:element atIndex:0];
            }
        }];
        
        return (_parentElements=partialParents);        
    }
}

/*
 Return the parent element only; don't use this to enumerate parents, use [parents].
 */
- (NMUIElement *)parentElement
{
    return [self elementAttributeWithName:kAXParentAttribute];
}

#pragma mark App Info

- (pid_t)pid
{
	pid_t result=-1;
	AXUIElementGetPid(_elementRef, &result);
	return result;
}

#pragma mark Text Selection

- (NSString *)selectedText
{
    return [self stringAttributeWithName:kAXSelectedTextAttribute];
}

#pragma mark Parent roles (including self)

// parents and own role 
- (NSArray *)selfAndParents
{
    NSMutableArray *result=[NSMutableArray arrayWithArray:[self parents]];
    [result insertObject:self atIndex:0];
    return result;
}

- (NSArray *)ownAndParentRoles
{
	NSMutableArray *result=[NSMutableArray array];
    for (NMUIElement *p in [self selfAndParents]) {
		if (p.role) {
			[result addObject:p.role];
		}
	}
    return result;
}

// find parent matching any of these roles
- (NMUIElement *)findParentWithRoles:(NSSet *)roles
{
    for (NMUIElement *p in [self selfAndParents]) {
		if ([roles containsObject:p.role]) {
			return p;
		}
	}
	return nil;
}

- (NMUIElement *)findParentWithRole:(NSString *)role
{
    return [self findParentWithRoles:[NSSet setWithObject:role]];
}

# pragma mark String Attributes

- (NSString *)subRole
{
    return [self stringAttributeWithName:kAXSubroleAttribute];
}

- (NSString *)title
{
    return [self stringAttributeWithName:kAXTitleAttribute];
}

- (NSString *)menuCmdCharacter
{
    return [self stringAttributeWithName:kAXMenuItemCmdCharAttribute];
}

- (NSNumber *)menuCmdKeycode
{
    return [self numberAttributeWithName:kAXMenuItemCmdVirtualKeyAttribute];    
}

- (NSNumber *)menuCmdModifiers
{
    return [self numberAttributeWithName:kAXMenuItemCmdModifiersAttribute];        
}

- (NSNumber *)menuCmdGlyph
{
    return [self numberAttributeWithName:kAXMenuItemCmdGlyphAttribute];    
}

#pragma mark Boolean Attributes

- (BOOL)selected
{
    return [self boolAttributeWithName:kAXSelectedAttribute];
}

- (BOOL)enabled
{
    return [self boolAttributeWithName:kAXEnabledAttribute];
}

- (BOOL)main
{
    return [self boolAttributeWithName:kAXMainAttribute];
}

- (BOOL)hasChildren
{
    return [[self arrayAttributeWithName:kAXChildrenAttribute] count]>0;
}

- (BOOL)hasSelectedChildren
{
    BOOL result=NO;
	CFArrayRef children=NULL;
	AXUIElementCopyAttributeValue(_elementRef, kAXSelectedChildrenAttribute, (CFTypeRef *)&children);
    if (children) {
        result=CFArrayGetCount(children)>0;
        CFRelease(children);
    }
    return result;
}

#pragma mark Window Attributes

- (NSPoint)origin
{
	CGPoint result=NSPointToCGPoint(NSZeroPoint);
	AXValueRef ref=NULL;
	AXUIElementCopyAttributeValue(_elementRef, kAXPositionAttribute, (CFTypeRef *)&ref);
	if(ref)
	{
		AXValueGetValue(ref, kAXValueCGPointType, &result);
        CFRelease(ref);
	}
	return NSPointFromCGPoint(result);
}

- (NSSize)size
{
	CGSize result=NSSizeToCGSize(NSZeroSize);
	AXValueRef ref=NULL;
	AXUIElementCopyAttributeValue(_elementRef, kAXSizeAttribute, (CFTypeRef *)&ref);
	if(ref)
	{
		AXValueGetValue(ref, kAXValueCGSizeType, &result);
        CFRelease(ref);        
	}
	return NSSizeFromCGSize(result);
}

- (NSRect)frame
{
	CGRect result=NSRectToCGRect(NSZeroRect);
	AXValueRef ref=NULL;
	AXUIElementCopyAttributeValue(_elementRef, kAXPositionAttribute, (CFTypeRef *)&ref);
	if(ref)
	{
		AXValueGetValue(ref, kAXValueCGPointType, &(result.origin));
        CFRelease(ref);        
	}
    ref=NULL;
	AXUIElementCopyAttributeValue(_elementRef, kAXSizeAttribute, (CFTypeRef *)&ref);
	if(ref)
	{
		AXValueGetValue(ref, kAXValueCGSizeType, &(result.size));
        CFRelease(ref);        
	}
	return NSRectFromCGRect(result);
}

- (NSNumber *)insertionPointLineNumber
{
    return [self numberAttributeWithName:kAXInsertionPointLineNumberAttribute];
}

- (NSNumber *)numberOfCharacters
{
    return [self numberAttributeWithName:kAXNumberOfCharactersAttribute];
}

#pragma mark Relates Elements

- (NMUIElement *)windowElement
{
    return [self elementAttributeWithName:kAXWindowAttribute];    
}

- (NSArray *)children
{
    return [self arrayAttributeWithName:kAXChildrenAttribute];
}

- (NMUIElement *)appElement
{
	AXUIElementRef result=[[self findParentWithRole:(NSString *)kAXApplicationRole] elementRef];
	return [[NMUIElement alloc] initWithElement:result];
}

- (NMUIElement *)menuBar
{
    NMUIElement *result=nil;
	AXUIElementRef app=[[self findParentWithRole:(NSString *)kAXApplicationRole] elementRef];
	if (app) {
        AXUIElementRef element=NULL;
		AXUIElementCopyAttributeValue(app, kAXMenuBarRole, (CFTypeRef *)&element);
        if (element) {
            result=[[NMUIElement alloc] initWithElement:element];        
            CFRelease(element);
        }
	}
    return result;
}

- (NMUIElement *)menuBarDirect
{
    return [self elementAttributeWithName:kAXMenuBarRole];
}

-(NMUIElement *)childAtIndex:(NSUInteger)index
{
	NMUIElement *result=nil;
    CFArrayRef itemChildren=NULL;
	AXUIElementCopyAttributeValue(_elementRef, kAXChildrenAttribute, (CFTypeRef *)&itemChildren);
	if (itemChildren) {
        if (CFArrayGetCount(itemChildren)>index) {
            result=[[NMUIElement alloc] initWithElement:CFArrayGetValueAtIndex(itemChildren, index)];
        }
        CFRelease(itemChildren);
	}
	return result;
}

- (NMUIElement *)closeButtonElement
{
    return [self elementAttributeWithName:kAXCloseButtonAttribute];
}

- (NMUIElement *)zoomButtonElement
{
    return [self elementAttributeWithName:kAXZoomButtonAttribute];    
}

- (NMUIElement *)minimizeButtonElement
{
    return [self elementAttributeWithName:kAXMinimizeButtonAttribute];    
}

- (NMUIElement *)toolbarButtonElement
{
    return [self elementAttributeWithName:kAXToolbarButtonAttribute];    
}



- (NMUIElement *)topLevelMenuWithIndex:(NSUInteger)index
{
	NMUIElement *result=nil;
	NMUIElement *menuBar=[self menuBar];
	if (menuBar) {
		NSArray *menus=[menuBar children];
		if ([menus count]>index) {
			result=[[NMUIElement alloc] initWithElement:(AXUIElementRef)menus[index]];
		}
	}
	return result;
}

static void _enumerate(void (^block)(NMUIElement *element, NSUInteger depth, const NSUInteger *path, BOOL *stop),
					   NMUIElement *element, BOOL *stop, NSUInteger depth, NSUInteger maxDepth, NSUInteger *path)
{
	// check depth
	if (depth>maxDepth) {
		return;
	}

	// call the block
	block(element, depth, path, stop);

	// we are going one level deeper
	NSUInteger *pathLocation=path+depth++;
	
	// enumerate any children
	NSArray *children=(NSArray *)[element children];
	if (children) {
		NSUInteger subChildIndex=0;
		for(id childRef in children)
		{
			if (*stop) {
				break;
			}
			NMUIElement *child=[[NMUIElement alloc] initWithElement:(AXUIElementRef)childRef];
			*pathLocation=subChildIndex++;
			_enumerate(block, child, stop, depth, maxDepth, path);
		}
	}
}

- (void)enumerateDescendentsToDepth:(NSUInteger)maxDepth
						 usingBlock:(void (^)(NMUIElement *element, NSUInteger depth, const NSUInteger *path, BOOL *stop))block;
{
	__block BOOL stop=NO;
	__block NSUInteger path[NM_UIELEMENT_MAX_PATH_DEPTH]={0};
	if (maxDepth>NM_UIELEMENT_MAX_PATH_DEPTH) {
		maxDepth=NM_UIELEMENT_MAX_PATH_DEPTH;
	}
	_enumerate(block, self, &stop, 0, maxDepth, path);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ with role %@", [super description], self.role];
}

@end

