//
//  JPSyncReader.m
//  CloudyTabs
//
//  Created by Josh Parnham on 28/09/18.
//  Copyright © 2017 Josh Parnham. All rights reserved.
//

#import "JPSyncReader.h"

#import "BookmarkSync.h"

@interface JPSyncReader ()

@property (strong, nonatomic) NSXPCConnection *connection;

@end

@implementation JPSyncReader

+ (BOOL)canReadFile {
    return NSClassFromString(@"WBSFetchedCloudTabDeviceOrCloseRequest") != nil;
}

+ (NSString *)filePath {
    return nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.connection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.apple.SafariBookmarksSyncAgent" options:(NSXPCConnectionOptions)0];
        
        __weak typeof(self) weakSelf = self;
        self.connection.interruptionHandler = ^{
            [[weakSelf.connection remoteObjectProxy] collectDiagnosticsDataWithCompletionHandler:^void(NSData *diagnosticsData) {
                NSLog(@"%@", diagnosticsData);
            }];
        };
        
        self.connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(WBSSafariBookmarksSyncAgentProtocol)];
        
        [[self.connection remoteObjectProxy] registerForPushNotificationsIfNeeded];
        
        NSSet *classes = [NSSet setWithArray:[NSArray arrayWithObjects:
                                              [WBSFetchedCloudTabDeviceOrCloseRequest class],
                                              [NSArray class],
                                              [NSString class],
                                              [NSDictionary class],
                                              [NSNumber class],
                                              [NSDate class],
                                              nil]
                          ];
        [self.connection.remoteObjectInterface setClasses:classes forSelector:@selector(fetchSyncedCloudTabDevicesAndCloseRequestsWithCompletionHandler:) argumentIndex:0 ofReply:YES];
        
        [self.connection resume];
    }
    return self;
}

- (NSArray *)deviceIDs {
    __block NSMutableArray *deviceNames = [[NSMutableArray alloc] init];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [[self.connection remoteObjectProxy] fetchSyncedCloudTabDevicesAndCloseRequestsWithCompletionHandler:^void(NSArray *cloudTabDevices, NSArray *closeRequests) {
        for (WBSFetchedCloudTabDeviceOrCloseRequest *request in cloudTabDevices) {
            NSString *name = [request.deviceOrCloseRequestDictionary objectForKey:@"DeviceName"];
            [deviceNames addObject:name];
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return deviceNames;
}

- (NSString *)deviceNameForID:(NSString *)deviceID {
    return deviceID;
}

- (NSArray *)tabsForDeviceID:(NSString *)deviceID {
    __block NSMutableArray *tabs;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [[self.connection remoteObjectProxy] fetchSyncedCloudTabDevicesAndCloseRequestsWithCompletionHandler:^void(NSArray *cloudTabDevices, NSArray *closeRequests) {
        for (WBSFetchedCloudTabDeviceOrCloseRequest *request in cloudTabDevices) {
            NSString *deviceName = [request.deviceOrCloseRequestDictionary objectForKey:@"DeviceName"];

            if ([deviceID isEqualToString:deviceName]) {
                tabs = [request.deviceOrCloseRequestDictionary objectForKey:@"Tabs"];
                dispatch_semaphore_signal(semaphore);
            }
        }
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return tabs;
}

- (NSDate * _Nullable)modificationDate {
    __block NSDate *mostRecentModificationDate;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [[self.connection remoteObjectProxy] fetchSyncedCloudTabDevicesAndCloseRequestsWithCompletionHandler:^void(NSArray *cloudTabDevices, NSArray *closeRequests) {
        for (WBSFetchedCloudTabDeviceOrCloseRequest *request in cloudTabDevices) {
            NSDate *lastModified = request.deviceOrCloseRequestDictionary[@"LastModified"];
            if (mostRecentModificationDate == nil || [lastModified compare: mostRecentModificationDate] == NSOrderedDescending) {
                mostRecentModificationDate = lastModified;
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return mostRecentModificationDate;
}

+ (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@", NSClassFromString(@"WBSFetchedCloudTabDeviceOrCloseRequest")];
}

@end
