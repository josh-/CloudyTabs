//
//  JPCloudTabsDBReader.m
//  CloudyTabs
//
//  Created by Josh Parnham on 9/10/17.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

#import "JPCloudTabsDBReader.h"

@interface JPCloudTabsDBReader ()

@property (strong, nonatomic) FMDatabase *cloudTabsDatabase;

@end

@implementation JPCloudTabsDBReader

+ (BOOL)canReadFile {
    NSString *path = [self filePath];
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    
    if ([db open] && [db tableExists:@"cloud_tabs"]) {
        [db close];
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)filePath {
    return [[self safariLibraryDirectory] stringByAppendingPathComponent:@"CloudTabs.db"];
}

+ (NSString *)safariLibraryDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [[paths firstObject] stringByAppendingPathComponent:@"Safari"];
}

- (FMDatabase *)cloudTabsDatabase {
    if (!_cloudTabsDatabase) {
        NSString *path = [[JPCloudTabsDBReader safariLibraryDirectory] stringByAppendingPathComponent:@"CloudTabs.db"];
        FMDatabase *db = [FMDatabase databaseWithPath:path];
        
        if ([db open]) {
            return db;
        } else {
            db = nil;
            return nil;
        }
    }
    return _cloudTabsDatabase;
}

- (NSArray *)deviceIDs {
    NSMutableArray *deviceIDs = [NSMutableArray new];
    
    FMResultSet *resultSet = [self.cloudTabsDatabase executeQuery:@"SELECT device_uuid from cloud_tab_devices GROUP BY device_uuid"];
    while ([resultSet next]) {
        [deviceIDs addObject:[resultSet stringForColumn:@"device_uuid"]];
    }
    
    return [deviceIDs copy];
}

- (NSString *)deviceNameForID:(NSString *)deviceID {
    FMResultSet *resultSet = [self.cloudTabsDatabase executeQuery:@"SELECT device_name from cloud_tab_devices WHERE device_uuid = ?", deviceID];
    while ([resultSet next]) {
        return [resultSet stringForColumn:@"device_name"];
    }
    
    return nil;
}

- (NSArray *)tabsForDeviceID:(NSString *)deviceID {
    NSMutableArray<NSDictionary *> *tabs = [NSMutableArray new];
    
    NSString *query = @"SELECT title, url from cloud_tabs WHERE device_uuid = ?";
    FMResultSet *resultSet = [self.cloudTabsDatabase executeQuery:query, deviceID];
    while ([resultSet next]) {
        NSString *URL = [resultSet stringForColumn:@"url"];
        NSString *title = [resultSet stringForColumn:@"title"];
        
        if (URL) {
            [tabs addObject:@{@"URL": URL, @"Title": (title ? title : URL)}];
        }
    }
    
    return [tabs copy];
}

- (NSDate * _Nullable)modificationDate {
    NSURL *preferencesURL = [NSURL fileURLWithPath:[[JPCloudTabsDBReader safariLibraryDirectory] stringByAppendingPathComponent:@"CloudTabs.db"]];
    
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
