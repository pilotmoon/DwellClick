// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMBlockUtils.h"
#import "NMBrowserHelper.h"
#import "NMEventUtils.h"
#import "NMFloatUtils.h"
#import "NMKeyCommander.h"

NSString *const NMBrowserHelperIdentifierCamino=@"org.mozilla.camino";
NSString *const NMBrowserHelperIdentifierChrome=@"com.google.Chrome";
NSString *const NMBrowserHelperIdentifierChromeCanary=@"com.google.Chrome.canary";
NSString *const NMBrowserHelperIdentifierFirefox=@"org.mozilla.firefox";
NSString *const NMBrowserHelperIdentifierFirefoxAurora=@"org.mozilla.aurora";
NSString *const NMBrowserHelperIdentifierFirefoxNightly=@"org.mozilla.nightly";
NSString *const NMBrowserHelperIdentifierOmniWeb=@"com.omnigroup.OmniWeb5";
NSString *const NMBrowserHelperIdentifierOpera=@"com.operasoftware.Opera";
NSString *const NMBrowserHelperIdentifierSafari=@"com.apple.Safari";
NSString *const NMBrowserHelperIdentifierWhiteHatAviator=@"com.whitehatsec.aviator";

NSString *const NMBrowserHelperDefaultBrowserOverride=@"NMBrowserHelperDefaultBrowserOverride";


static NSURL *_dummyHttpUrl;
static NSSet *_knownBrowsers;
static NSSet *_chromeGroup;
static NSSet *_firefoxGroup;
static NSDictionary *_searchRoutines;

/*
 Escape the backslash and double-quote characters, which are the special literal string characters in AppleScript.
 (See http://developer.apple.com/library/mac/documentation/applescript/conceptual/applescriptlangguide/reference/ASLR_classes.html
 under "Special String Characters".)
 */
static NSString *_appleScriptSafe(NSString *str)
{
    return [[str stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
}

/*
 Run the given string as an AppleScript.
 */
static NSString *_runAppleScript(NSString *script)
{
    NSString *result=nil;
    NSAppleScript *const scriptObj=[[NSAppleScript alloc] initWithSource:script];
    if (scriptObj) {
        NSDictionary *error = nil;
        // we use try/catch because this might throw an exception.
        @try {
            NSAppleEventDescriptor *desc=[scriptObj executeAndReturnError:&error];
            result=[desc stringValue];
        }
        @catch (NSException *exception) {
            NMLogError(@"Caught exception in _runAppleScript: %@", exception);
        }
    }
    return result;
}

/*
 Common part of script for both Chrome and Firefox. Open app, new tab (cmd-t) and wait to
 make sure a window is actually open.
 */
//static NSString *_stubScriptForApp(NSString *bundleIdentifier)
//{
//    NSString *const path=[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleIdentifier];
//	if (path) {
//		NSString *const displayName=[[NSFileManager defaultManager] displayNameAtPath:path];
//        if (displayName) {
//            return [NSString stringWithFormat:
//                    @"tell application \"%@\"\n"
//                    @"  activate\n"
//                    @"  repeat while bundle identifier of (info for (path to frontmost application)) is not \"%@\"\n"
//                    @"    delay 0.05\n"                                             
//                    @"  end repeat\n"
//                    @"  tell application \"System Events\"\n"
//                    @"    keystroke \"t\" using command down\n"
//                    @"  end tell\n"
//                    @"  repeat while name of window 1 is \"\"\n"
//                    @"    delay 0.05\n"                                             
//                    @"  end repeat\n"
//                    @"end tell\n", displayName, bundleIdentifier];
//        }
//	}
//    return nil;
//}

@implementation NMBrowserHelper

+ (void)initialize
{
    if (self==[NMBrowserHelper class]) {
        _dummyHttpUrl=[NSURL URLWithString:@"http://example.com/"];
        
        _chromeGroup=[NSSet setWithObjects:
                      NMBrowserHelperIdentifierChrome,
                      NMBrowserHelperIdentifierChromeCanary,
                      NMBrowserHelperIdentifierWhiteHatAviator,
                      nil];
        
        _firefoxGroup=[NSSet setWithObjects:
                       NMBrowserHelperIdentifierFirefox,
                       NMBrowserHelperIdentifierFirefoxAurora,
                       NMBrowserHelperIdentifierFirefoxNightly,
                       nil];
        
        
        _knownBrowsers=[NSSet setWithObjects:
                        NMBrowserHelperIdentifierSafari,
                        NMBrowserHelperIdentifierOpera,
                        NMBrowserHelperIdentifierOmniWeb,
                        NMBrowserHelperIdentifierCamino,
                        nil];
        _knownBrowsers=[_knownBrowsers setByAddingObjectsFromSet:_chromeGroup];
        _knownBrowsers=[_knownBrowsers setByAddingObjectsFromSet:_firefoxGroup];
        
        /*
         Broswer-specific routines to initiate a search. All take a single text string parameter.
         */
        _searchRoutines=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                         
                         /*
                          Safari is nice to us. Just one line of AppleScript.
                          */
                         ^(NSString *const text) {
                             _runAppleScript([NSString stringWithFormat:
                                              @"tell application id \"%@\"\n"
                                              @"  activate\n"
                                              @"  search the web for \"%@\"\n"
                                              @"end tell\n", NMBrowserHelperIdentifierSafari, _appleScriptSafe(text)]);
                         },
                         NMBrowserHelperIdentifierSafari,
                         
                         nil];
    }
}

/*
 Bundle identifiers of all known browsers.
 */
+ (NSSet *)knownBrowsers
{
    return _knownBrowsers;
}

+ (NSSet *)knownBrowsersChromeGroup
{
    return _chromeGroup;
}

+ (NSSet *)knownBrowsersFirefoxGroup
{
    return _firefoxGroup;
}

/* 
 Bundle identifier of the default browser.
 */
+ (NSString *)defaultBrowser
{    
    NSString *const overrideBrowser=[[NSUserDefaults standardUserDefaults] stringForKey:NMBrowserHelperDefaultBrowserOverride];
    if ([overrideBrowser length]>0) {
        return overrideBrowser;
    }
    
    // return system default
    return [[NSBundle bundleWithURL:[[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:_dummyHttpUrl]] bundleIdentifier];
}

/*
 Return the most appropriate browser to use for an action taken in the given app.
 */
+ (NSString *)bestBrowserFromApp:(NSString *)bundleIdentifier
{
    return [[self knownBrowsers] containsObject:bundleIdentifier]?bundleIdentifier:[self defaultBrowser];
}

+ (void)openUrl:(NSURL *)url withApp:(NSString *)bundleIdentifier
{
    if (!url) return;
    NMLogFine(@"Opening URL %@ with app %@", url, bundleIdentifier);    
    [[NSWorkspace sharedWorkspace] openURLs:@[url]
                    withAppBundleIdentifier:bundleIdentifier
                                    options:NSWorkspaceLaunchDefault
             additionalEventParamDescriptor:NULL
                          launchIdentifiers:NULL];
}

/*
 Open a URL in the most suitable application, given the app that
 the user is currently using.
 
 If the passed-in app is a known brower, open it there. Else, open 
 it in the default browser.
 */
+ (void)openUrl:(NSURL *)url fromApp:(NSString *)bundleIdentifier
{
    [self openUrl:url withApp:[self bestBrowserFromApp:bundleIdentifier]];
}

/*
 Search for given text in given browser, if the browser supports it.
 Return YES if browser supports it, else NO.
 */
+ (BOOL)searchForText:(NSString *)searchText withApp:(NSString *)bundleIdentifier
{
    void (^searchRoutine)(NSString *)=_searchRoutines[bundleIdentifier];
    if (searchRoutine) {
        if ([searchText length]>0) {
            NMRunAsyncInBackground(^{searchRoutine(searchText);});
        }
        return YES;
    }
    return NO;
}

/*
 Attempts to perform a web search for the given text, in the most suitable browser. Given the app
 the user is currently using.

 Return YES if a search was invoked, NO if the browser did not support it.
 */
+ (BOOL)searchForText:(NSString *)searchText fromApp:(NSString *)bundleIdentifier
{
    return [self searchForText:searchText
                       withApp:[self bestBrowserFromApp:bundleIdentifier]];
}

+ (NSURL *)getFrontmostUrlForApp:(NSString *)bundleIdentifier
{
    NSURL *result=nil;
    NSString *resultStr=nil;
    if (bundleIdentifier&&[[NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier] count]>0) {
        if ([bundleIdentifier isEqualToString:NMBrowserHelperIdentifierSafari]) {
            resultStr=_runAppleScript([NSString stringWithFormat:@"tell application id \"%@\"\n"
                                      @"get URL of current tab of window 1\n"
                                      @"end tell\n", bundleIdentifier]);
            
        }
        else if ([_chromeGroup containsObject:bundleIdentifier]) {
            resultStr=_runAppleScript([NSString stringWithFormat:@"tell application id \"%@\"\n"
                                      @"get URL of active tab of first window\n"
                                      @"end tell\n", bundleIdentifier]);
        }
    }
    if ([resultStr hasPrefix:@"http"]) {
        result=[NSURL URLWithString:resultStr];
    }
    return result;
}

+ (NSString *)getFrontmostTitleForApp:(NSString *)bundleIdentifier
{
    NSString *resultStr=nil;
    if (bundleIdentifier&&[[NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier] count]>0) {
        if ([bundleIdentifier isEqualToString:NMBrowserHelperIdentifierSafari]) {
            resultStr=_runAppleScript([NSString stringWithFormat:@"tell application id \"%@\"\n"
                                      @"get name of current tab of window 1\n"
                                      @"end tell\n", bundleIdentifier]);
            
        }
        else if ([_chromeGroup containsObject:bundleIdentifier]) {
            resultStr=_runAppleScript([NSString stringWithFormat:@"tell application id \"%@\"\n"
                                      @"get title of active tab of first window\n"
                                      @"end tell\n", bundleIdentifier]);
        }
    }
    return resultStr;
}

@end
