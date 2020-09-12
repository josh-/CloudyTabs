//
//  JPCloudTabsDBReader.m
//  CloudyTabs
//
//  Created by Josh Parnham on 9/10/17.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

#import <FMDB/FMDB.h>

#import "JPCloudTabsDBReader.h"

@interface JPCloudTabsDBReader ()

@property (strong, nonatomic) FMDatabase *cloudTabsDatabase;

@end

@implementation JPCloudTabsDBReader

- (NSString *)cloudTabsDBFile {
    return [[JPCloudTabsDBReader safariLibraryDirectory] stringByAppendingPathComponent:@"CloudTabs.db"];
}

- (BOOL)permissionsToReadFile {
    NSString *filePath = [self cloudTabsDBFile];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    return fileExists && data != nil;
}

- (void)fetchTabData:(void (^_Nonnull)(NSArray<NSDictionary *> *_Nullable))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableArray *items = [[NSMutableArray alloc] init];
    
        for (NSString *deviceID in self.deviceIDs) {
            NSString *name = [self deviceNameForID:deviceID];
    
            NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
            [dictionary setValue:name forKey:@"DeviceName"];
    
            [dictionary setValue:[self tabsForDeviceID:deviceID] forKey:@"Tabs"];
    
            [items addObject:dictionary.copy];
        }
    
        completionHandler(items.copy);
    });
}

- (void)fetchDatabaseModificationDate:(void (^_Nonnull)(NSDate *_Nullable))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        completionHandler(self.modificationDate);
    });
}

# pragma mark - Private

+ (NSString *)safariLibraryDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [[paths firstObject] stringByAppendingPathComponent:@"Safari"];
}

- (FMDatabase *)cloudTabsDatabase {
    if (!_cloudTabsDatabase) {
        FMDatabase *db = [FMDatabase databaseWithPath:[self cloudTabsDBFile]];
        
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

@end
