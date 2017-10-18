//
//  JPSyncedPreferencesReader.m
//  CloudyTabs
//
//  Created by Josh Parnham on 9/10/17.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

#import "JPSyncedPreferencesReader.h"

@implementation JPSyncedPreferencesReader

+ (BOOL)canReadFile {
    NSDictionary *dictionary = [self syncedPreferenceDictionary];
    
    if ([dictionary[@"values"] allKeys].count > 0) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)filePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    
    NSString *syncedPreferencesPath = [paths[0] stringByAppendingPathComponent:@"SyncedPreferences"];
    
    return [syncedPreferencesPath stringByAppendingPathComponent:@"com.apple.Safari.plist"];
}

+ (NSDictionary *)syncedPreferenceDictionary {
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:[self filePath]];
    
    return dictionary;
}


- (NSArray *)deviceIDs {
    NSDictionary *dictionary = [JPSyncedPreferencesReader syncedPreferenceDictionary];

    NSMutableArray *deviceIDs = [[NSMutableArray alloc] init];

    for (NSString *deviceID in [dictionary[@"values"] allKeys]) {
        // Hide devices that haven't had activity in the last week (604800 = 7×24×60×60 = one week in seconds)
        if ([dictionary[@"values"][deviceID][@"value"][@"LastModified"] timeIntervalSinceNow] < 604800) {
            [deviceIDs addObject:deviceID];
        }
    }
    
    return deviceIDs;
}

- (NSString *)deviceNameForID:(NSString *)deviceID {
    NSDictionary *dictionary = [JPSyncedPreferencesReader syncedPreferenceDictionary];

    return dictionary[@"values"][deviceID][@"value"][@"DeviceName"];
}

- (NSArray *)tabsForDeviceID:(NSString *)deviceID {
    NSDictionary *dictionary = [JPSyncedPreferencesReader syncedPreferenceDictionary];

    return dictionary[@"values"][deviceID][@"value"][@"Tabs"];
}

- (NSDate * _Nullable)modificationDate {
    NSURL *preferencesURL = [NSURL fileURLWithPath:[JPSyncedPreferencesReader filePath]];
    
    NSDate *modificationDate;
    if ([preferencesURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil]) {
        return modificationDate;
    }
    else {
        return nil;
    }
}

+ (NSString *)debugDescription {
    NSString *filePath = [self filePath];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    
    return [NSString stringWithFormat:@"%@ exists? %hhd (%llu)", filePath, fileExists, fileSize];
}

@end
