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

- (void)fetchTabData:(void (^_Nonnull)(NSArray *_Nullable))completionHandler {
    [[self.connection remoteObjectProxy] fetchSyncedCloudTabDevicesAndCloseRequestsWithCompletionHandler:^void(NSArray *cloudTabDevices, NSArray *closeRequests) {
        
        NSMutableArray *data = [NSMutableArray new];
        
        for (WBSFetchedCloudTabDeviceOrCloseRequest *request in cloudTabDevices) {
            NSString *deviceName = request.deviceOrCloseRequestDictionary[@"DeviceName"];
            NSArray *tabs = request.deviceOrCloseRequestDictionary[@"Tabs"];
            
            if (deviceName && tabs) {
                [data addObject:@{@"DeviceName": deviceName, @"Tabs": tabs}];
            }
        }
        
        completionHandler(data);
    }];
}

@end
