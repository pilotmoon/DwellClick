// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import <Cocoa/Cocoa.h>
@class NMPoint;

#define NM_UIELEMENT_MAX_PATH_DEPTH 10

@interface NMUIElement : NSObject {
#ifdef __OBJC_GC__    
	__strong 
#endif
    AXUIElementRef _elementRef;
    NSArray *_parentElements; // note: parents does not include self
    NSString *_role;
    NSSet *_attributeNames;
}
@property (readonly) AXUIElementRef elementRef;

@property (readonly) pid_t pid;

@property (readonly) NSString *selectedText;

@property (readonly) NSString *role;
@property (readonly) NSString *subRole;
@property (readonly) NSString *title;
@property (readonly) NSString *menuCmdCharacter;
@property (readonly) NSNumber *menuCmdGlyph;
@property (readonly) NSNumber *menuCmdKeycode;
@property (readonly) NSNumber *menuCmdModifiers;
@property (readonly) NSSize size;
@property (readonly) NSPoint origin;
@property (readonly) NSRect frame;

@property (readonly) BOOL selected;
@property (readonly) BOOL enabled;
@property (readonly) BOOL main;
@property (readonly) BOOL hasChildren;
@property (readonly) BOOL hasSelectedChildren;

@property (readonly) NSArray *parents;
@property (readonly) NSArray *selfAndParents;
@property (readonly) NSArray *ownAndParentRoles;
@property (readonly) NMUIElement *appElement;
@property (readonly) NMUIElement *menuBarDirect;
@property (readonly) NMUIElement *menuBar;
@property (readonly) NMUIElement *parentElement;
@property (readonly) NMUIElement *windowElement;
@property (readonly) NMUIElement *closeButtonElement;
@property (readonly) NMUIElement *zoomButtonElement;
@property (readonly) NMUIElement *minimizeButtonElement;
@property (readonly) NMUIElement *toolbarButtonElement;

@property (readonly) NSSet *attributeNames;
@property (readonly) NSArray *actionNames;
@property (readonly) NSArray *children;  // children as array of ACUIElementRef
@property (readonly) NSNumber *insertionPointLineNumber;
@property (readonly) NSNumber *numberOfCharacters;



+ (AXError)lastError;
+ (NMUIElement *)elementAtLocation:(NMPoint *)point
						   timeout:(NSTimeInterval)timeout;

- (NMUIElement *)childAtIndex:(NSUInteger)index;
- (id)initWithElement:(AXUIElementRef)element;
- (void)performAction:(NSString *)name;
- (NMUIElement *)findParentWithRoles:(NSSet *)roles;
- (NMUIElement *)findParentWithRole:(NSString *)role;
- (NMUIElement *)topLevelMenuWithIndex:(NSUInteger)index;

- (id)genericAttributeWithName:(CFStringRef)attributeName;
- (NSString *)stringAttributeWithName:(CFStringRef)attributeName;
- (NSNumber *)numberAttributeWithName:(CFStringRef)attributeName;
- (NSArray *)arrayAttributeWithName:(CFStringRef)attributeName;
- (NMUIElement *)elementAttributeWithName:(CFStringRef)attributeName;
- (BOOL)boolAttributeWithName:(CFStringRef)attributeName;

- (void)enumerateDescendentsToDepth:(NSUInteger)depth
						 usingBlock:(void (^)(NMUIElement *element, NSUInteger depth, const NSUInteger *path, BOOL *stop))block; // nested enumeration of all children

@end