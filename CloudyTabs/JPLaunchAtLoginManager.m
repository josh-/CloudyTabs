//
//  JPLaunchAtLoginManager.m
//  CloudyTabs
//
//  Created by Josh Parnham on 30/8/20.
//  Copyright © 2020 Josh Parnham. All rights reserved.
//

#import "JPLaunchAtLoginManager.h"

#import <ServiceManagement/ServiceManagement.h>

@implementation JPLaunchAtLoginManager

+ (BOOL)willStartAtLogin:(NSString *)helperBundleId
{
    // Despite being deprecated, still the preffered API
    // https://github.com/alexzielenski/StartAtLoginController/issues/12#issuecomment-307525807
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFArrayRef jobDictionariesRef = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    #pragma clang diagnostic pop
    
    NSArray *jobDictionaries = CFBridgingRelease(jobDictionariesRef);
    
    if (jobDictionaries == nil) {
        return false;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Label = %@", helperBundleId];
    NSArray *filterdArray = [jobDictionaries filteredArrayUsingPredicate:predicate];
    if (filterdArray.count == 0) {
        return false;
    }
    
    NSDictionary *launchItem = filterdArray[0];
    return [[launchItem objectForKey:@"OnDemand"] boolValue];
}

+ (void)setStartAtLogin:(NSString *)helperBundleId enabled:(BOOL)enabled
{
    SMLoginItemSetEnabled((__bridge CFStringRef)(helperBundleId), enabled);
}

@end
