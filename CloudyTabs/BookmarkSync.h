//
//  BookmarkSync.h
//  CloudyTabs
//
//  Created by Josh Parnham on 5/8/18.
//  Copyright © 2018 Josh Parnham. All rights reserved.
//

#ifndef BookmarkSync_h
#define BookmarkSync_h

@protocol WBSCyclerCloudBookmarksAssistant <NSObject>
- (void)migrateToCloudKitWithCompletionHandler:(void (^)(NSError *))arg1;
- (void)generateDAVServerIDsForExistingBookmarksWithCompletionHandler:(void (^)(NSError *))arg1;
- (void)clearLocalDataIncludingMigrationState:(BOOL)arg1 completionHandler:(void (^)(NSError *))arg2;
- (void)resetToDAVDatabaseWithCompletionHandler:(void (^)(NSError *))arg1;
@end

@protocol WBSSafariBookmarksSyncAgentProtocol <WBSCyclerCloudBookmarksAssistant>
- (void)fetchSyncedCloudTabDevicesAndCloseRequestsWithCompletionHandler:(void (^)(NSArray *, NSArray *))arg1;
- (void)deleteCloudTabCloseRequestsWithUUIDStrings:(NSArray *)arg1 completionHandler:(void (^)(NSError *))arg2;
- (void)deleteDevicesWithUUIDStrings:(NSArray *)arg1 completionHandler:(void (^)(NSError *))arg2;
- (void)saveCloudTabCloseRequestWithDictionaryRepresentation:(NSDictionary *)arg1 closeRequestUUIDString:(NSString *)arg2 completionHandler:(void (^)(NSError *))arg3;
- (void)saveTabsForCurrentDeviceWithDictionaryRepresentation:(NSDictionary *)arg1 deviceUUIDString:(NSString *)arg2;
- (void)collectDiagnosticsDataWithCompletionHandler:(void (^)(NSData *))arg1;
- (void)beginMigrationFromDAV;
- (void)observeRemoteMigrationStateForSecondaryMigration;
- (void)fetchRemoteMigrationStateWithCompletionHandler:(void (^)(long long, NSString *, NSError *))arg1;
- (void)fetchUserIdentityWithCompletionHandler:(void (^)(NSString *, NSError *))arg1;
- (void)userAccountDidChange:(long long)arg1;
- (void)userDidUpdateBookmarkDatabase;
- (void)registerForPushNotificationsIfNeeded;
@end

@interface WBSFetchedCloudTabDeviceOrCloseRequest : NSObject <NSSecureCoding>
{
    NSString *_uuidString;
    NSDictionary *_deviceOrCloseRequestDictionary;
}

+ (BOOL)supportsSecureCoding;
@property(readonly, copy, nonatomic) NSDictionary *deviceOrCloseRequestDictionary; // @synthesize deviceOrCloseRequestDictionary=_deviceOrCloseRequestDictionary;
@property(readonly, copy, nonatomic) NSString *uuidString; // @synthesize uuidString=_uuidString;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (id)initWithUUIDString:(id)arg1 deviceOrCloseRequestDictionary:(id)arg2;

@end

#endif /* BookmarkSync_h */
