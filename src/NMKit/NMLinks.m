// This file is part of DwellClick <https://pilotmoon.com/dwellclick/>
// SPDX-License-Identifier: Apache-2.0

#import "NMLinks.h"
#import "NMAppUtils.h"
#import "NMBlockUtils.h"

@implementation NMLinks

+ (NSString *)cleanString:(id)obj
{
    return [obj isKindOfClass:[NSString class]] ? obj : @"unk";
}

+ (NSString *)binaryIdentifier
{
    return @"0";
}

+ (NSString *)identifier
{
    return @"0";
}

+ (NSString *)appStoreIdentifier
{
    return @"0";
}

+ (NSString *)displayName
{
    return @"0";
}

+ (NSString *)licenseString
{
    return @"free";
}

+ (NSString *)appToken
{
    NSArray *info=@[[NMLinks cleanString:[[self class] binaryIdentifier]],
                   [NMLinks cleanString:[NMAppVersionNumber() stringValue]],
                   [NMLinks cleanString:[self licenseString]]];
    return [info componentsJoinedByString:@"-"];
}

+ (NSURL *)makeLink:(NSString *)name
{
    NSString *string=[NSString stringWithFormat:@"http://pilotmoon.com/link/%@/%@", [self identifier], name];
    NMLogInfo(@"Made link: %@", string);
    return [NSURL URLWithString:string];
}

+ (void)openLink:(NSString *)name
{
    [[NSWorkspace sharedWorkspace] openURL:[self makeLink:name]];
}

+ (void)composeFeedbackEmail
{
    NSString *addr=@"\"Pilotmoon Support\" <support@pilotmoon.com>";
    NSString *subj=[NSString stringWithFormat:@"%@ Feedback", [self displayName]];
    NSString *body=[NSString stringWithFormat:@"Here's how I feel about %@:\n\n--\n(I'm using %@ %@ (%@) with Mac OS X %@ on %@)\n",
                    [self displayName],
                    [self displayName],
                    NMAppVersionString(),
                    [self appToken],
                    NMOSVersionString(),
                    NMModelIdentifier(),
                    nil
                    ];
    NSString *urls=[[NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", addr, subj, body, nil] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urls]];
}

+ (NSString *)appStoreURL
{
    return [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", [self appStoreIdentifier]];
}

+ (void)openAppStore
{
    NSURL *url=[NSURL URLWithString:[self appStoreURL]];
    if (url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

@end
