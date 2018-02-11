//
//  JPUserDefaultsController.m
//  CloudyTabs
//
//  Created by Josh Parnham on 11/2/18.
//  Copyright © 2018 Josh Parnham. All rights reserved.
//

#import "JPUserDefaultsController.h"

@implementation JPUserDefaultsController

static NSString *const LIST_ALL_DEVICES_KEY = @"ListAllDevices";

+ (void)registerUserDefaults {
    NSDictionary *defaultValues = @{LIST_ALL_DEVICES_KEY: @NO};
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

+ (BOOL)shouldListAllDevices {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

    return [standardUserDefaults boolForKey:LIST_ALL_DEVICES_KEY];
}

@end
